// lib/services/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';

/// Centralized API client with authentication, rate limiting, and error handling
class ApiClient {
  /// Enable/disable debug logging for all API calls
  static bool enableDebugLogs = kDebugMode;
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _cachedToken;
  String? _cachedRefreshToken;
  DateTime? _lastTokenCheck;
  static const Duration _tokenCacheTimeout = Duration(minutes: 1);

  // Token refresh state
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  // Rate limit tracking
  final Map<String, RateLimitInfo> _rateLimits = {};

  // Request deduplication - prevents duplicate simultaneous requests
  final Map<String, Future<ApiResponse>> _pendingRequests = {};
  static const Duration _requestDedupeWindow = Duration(seconds: 1);

  // Callbacks for global error handling
  Function()? onAuthenticationError;
  Function(String message)? onRateLimitError;
  Function(String message)? onAuthorizationError;

  // Callback for when token refresh completes (notify socket service)
  Function()? onTokenRefreshed;

  /// Get the base URL
  String get baseUrl => Endpoints.baseURL;

  /// Log API request/response for debugging
  void _logRequest(String method, String url, {dynamic body}) {
    if (!enableDebugLogs) return;
    final bodyStr = body != null ? ' body=${body.toString().length > 200 ? '${body.toString().substring(0, 200)}...' : body}' : '';
    debugPrint('[API] >> $method $url$bodyStr');
  }

  void _logResponse(String method, String url, int statusCode, int durationMs, {dynamic body, String? error}) {
    if (!enableDebugLogs) return;
    if (error != null) {
      debugPrint('[API] << $method $url [$statusCode] ${durationMs}ms ERROR: $error');
    } else {
      final dataStr = body != null ? ' ${body.toString().length > 300 ? '${body.toString().substring(0, 300)}...' : body}' : '';
      debugPrint('[API] << $method $url [$statusCode] ${durationMs}ms$dataStr');
    }
  }

  /// Get auth token with caching
  Future<String?> _getToken() async {
    // Use cached token if recent
    if (_cachedToken != null && _lastTokenCheck != null) {
      final elapsed = DateTime.now().difference(_lastTokenCheck!);
      if (elapsed < _tokenCacheTimeout) {
        return _cachedToken;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    _cachedRefreshToken = prefs.getString('refreshToken');
    _lastTokenCheck = DateTime.now();
    return _cachedToken;
  }

  /// Clear cached token (call on logout)
  void clearTokenCache() {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _lastTokenCheck = null;
  }

  /// Refresh access token using refresh token
  /// Returns new token on success, null on failure
  Future<String?> _refreshAccessToken() async {
    // If already refreshing, wait for the result
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      // Get refresh token from cache or storage
      if (_cachedRefreshToken == null) {
        final prefs = await SharedPreferences.getInstance();
        _cachedRefreshToken = prefs.getString('refreshToken');
      }

      if (_cachedRefreshToken == null || _cachedRefreshToken!.isEmpty) {
        return null;
      }


      final url = Uri.parse('$baseUrl${Endpoints.refreshTokenURL}');
      final response = await http.post(
        url,
        body: jsonEncode({'refreshToken': _cachedRefreshToken}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newToken = responseData['token'] ?? responseData['data']?['token'];
        final newRefreshToken = responseData['refreshToken'] ??
                                responseData['data']?['refreshToken'];

        if (newToken != null && newToken.isNotEmpty) {
          // Update cached tokens
          _cachedToken = newToken;
          _lastTokenCheck = DateTime.now();

          // Update refresh token if rotated
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            _cachedRefreshToken = newRefreshToken;
          }

          // Save to storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', newToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString('refreshToken', newRefreshToken);
          }


          // Notify listeners (e.g., socket service)
          onTokenRefreshed?.call();

          // Complete all waiting refresh requests
          for (final completer in _refreshQueue) {
            completer.complete(newToken);
          }
          _refreshQueue.clear();

          return newToken;
        }
      }


      // Complete all waiting requests with null
      for (final completer in _refreshQueue) {
        completer.complete(null);
      }
      _refreshQueue.clear();

      return null;
    } catch (e) {

      // Complete all waiting requests with null
      for (final completer in _refreshQueue) {
        completer.complete(null);
      }
      _refreshQueue.clear();

      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Get default headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Parse rate limit headers from response
  void _parseRateLimitHeaders(http.Response response, String endpoint) {
    final limit = response.headers['ratelimit-limit'];
    final remaining = response.headers['ratelimit-remaining'];
    final reset = response.headers['ratelimit-reset'];

    if (limit != null && remaining != null && reset != null) {
      _rateLimits[endpoint] = RateLimitInfo(
        limit: int.tryParse(limit) ?? 0,
        remaining: int.tryParse(remaining) ?? 0,
        resetTime: DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(reset) ?? 0) * 1000,
        ),
      );
    }
  }

  /// Get remaining rate limit for an endpoint
  RateLimitInfo? getRateLimitInfo(String endpoint) => _rateLimits[endpoint];

  /// Check if we should wait before making a request
  Duration? getWaitTime(String endpoint) {
    final info = _rateLimits[endpoint];
    if (info != null && info.remaining <= 0) {
      final now = DateTime.now();
      if (info.resetTime.isAfter(now)) {
        return info.resetTime.difference(now);
      }
    }
    return null;
  }

  /// Handle response and extract data/error
  ApiResponse _handleResponse(http.Response response, String endpoint) {
    _parseRateLimitHeaders(response, endpoint);

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    switch (response.statusCode) {
      case 200:
      case 201:
        // If response has pagination info, return full body to preserve it
        // Otherwise extract 'data' field if available
        final hasDataAndPagination = body.containsKey('data') && body.containsKey('pagination');
        return ApiResponse(
          success: true,
          data: hasDataAndPagination ? body : (body['data'] ?? body),
          statusCode: response.statusCode,
        );

      case 401:
        // Authentication error - token expired or invalid
        onAuthenticationError?.call();
        return ApiResponse(
          success: false,
          error: body['error'] ?? 'Authentication required. Please log in again.',
          statusCode: 401,
        );

      case 403:
        // Authorization error - user doesn't have permission
        final errorMessage = body['error'] ?? 'You don\'t have permission to do this';
        onAuthorizationError?.call(_getReadableAuthError(errorMessage));
        return ApiResponse(
          success: false,
          error: _getReadableAuthError(errorMessage),
          statusCode: 403,
        );

      case 429:
        // Rate limit exceeded
        final errorMessage = body['error'] ?? 'Too many requests. Please slow down.';
        onRateLimitError?.call(_getReadableRateLimitError(errorMessage));
        return ApiResponse(
          success: false,
          error: _getReadableRateLimitError(errorMessage),
          statusCode: 429,
          rateLimitInfo: _rateLimits[endpoint],
        );

      case 404:
        return ApiResponse(
          success: false,
          error: body['error'] ?? 'Resource not found',
          statusCode: 404,
        );

      case 500:
      case 502:
      case 503:
        return ApiResponse(
          success: false,
          error: 'Server error. Please try again later.',
          statusCode: response.statusCode,
        );

      default:
        return ApiResponse(
          success: false,
          error: body['error'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
    }
  }

  /// Convert backend error messages to user-friendly messages
  String _getReadableAuthError(String error) {
    if (error.contains('Not authorized to view this message')) {
      return 'This message is private';
    }
    if (error.contains('Not authorized to update this user')) {
      return 'You can only edit your own profile';
    }
    if (error.contains('Not authorized to delete this comment')) {
      return 'You can only delete your own comments';
    }
    if (error.contains('Not authorized')) {
      return 'You don\'t have permission to do this';
    }
    return error;
  }

  /// Convert rate limit error messages to user-friendly messages
  String _getReadableRateLimitError(String error) {
    if (error.contains('interactions')) {
      return 'Slow down! Try again in a moment';
    }
    if (error.contains('reports')) {
      return 'Report limit reached. Try again in an hour';
    }
    if (error.contains('search')) {
      return 'Search limit reached. Please wait';
    }
    if (error.contains('AI') || error.contains('requests')) {
      return 'AI usage limit reached. Upgrade for more';
    }
    return 'Too many requests. Please wait a moment';
  }

  /// Generate a unique key for request deduplication
  String _getRequestKey(String method, String endpoint, Map<String, String>? queryParams) {
    final params = queryParams?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$method:$endpoint?$params';
  }

  /// GET request with automatic 401 token refresh and request deduplication
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    bool deduplicate = true,
  }) async {
    // Request deduplication - return existing pending request if available
    final requestKey = _getRequestKey('GET', endpoint, queryParams);
    if (deduplicate && _pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey]!;
    }

    final future = _executeGet(endpoint, queryParams: queryParams, requiresAuth: requiresAuth);

    if (deduplicate) {
      _pendingRequests[requestKey] = future;
      // Clean up after request completes
      future.whenComplete(() {
        Future.delayed(_requestDedupeWindow, () {
          _pendingRequests.remove(requestKey);
        });
      });
    }

    return future;
  }

  /// Internal GET execution
  Future<ApiResponse> _executeGet(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      // Check rate limit before request
      final waitTime = getWaitTime(endpoint);
      if (waitTime != null) {
        return ApiResponse(
          success: false,
          error: 'Please wait ${waitTime.inSeconds} seconds',
          statusCode: 429,
        );
      }

      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );
      final headers = await _getHeaders(includeAuth: requiresAuth);

      _logRequest('GET', uri.toString());
      final stopwatch = Stopwatch()..start();
      final response = await http.get(uri, headers: headers);
      stopwatch.stop();
      final result = _handleResponse(response, endpoint);
      _logResponse('GET', endpoint, response.statusCode, stopwatch.elapsedMilliseconds,
          body: result.success ? result.data : null, error: result.error);

      // Auto-refresh token on 401 and retry
      if (result.isUnauthorized && requiresAuth) {
        final newToken = await _refreshAccessToken();

        if (newToken != null) {
          // Retry with new token
          final retryHeaders = await _getHeaders(includeAuth: true);
          final retryResponse = await http.get(uri, headers: retryHeaders);
          return _handleResponse(retryResponse, endpoint);
        } else {
          // Token refresh failed - trigger auth error callback
          onAuthenticationError?.call();
        }
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// POST request with automatic 401 token refresh
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      _logRequest('POST', uri.toString(), body: body);
      final stopwatch = Stopwatch()..start();
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();
      final result = _handleResponse(response, endpoint);
      _logResponse('POST', endpoint, response.statusCode, stopwatch.elapsedMilliseconds,
          body: result.success ? result.data : null, error: result.error);

      // Auto-refresh token on 401 and retry
      if (result.isUnauthorized && requiresAuth) {
        final newToken = await _refreshAccessToken();

        if (newToken != null) {
          // Retry with new token
          final retryHeaders = await _getHeaders(includeAuth: true);
          final retryResponse = await http.post(
            uri,
            headers: retryHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          return _handleResponse(retryResponse, endpoint);
        } else {
          // Token refresh failed - trigger auth error callback
          onAuthenticationError?.call();
        }
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// PUT request with automatic 401 token refresh
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      _logRequest('PUT', uri.toString(), body: body);
      final stopwatch = Stopwatch()..start();
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();
      final result = _handleResponse(response, endpoint);
      _logResponse('PUT', endpoint, response.statusCode, stopwatch.elapsedMilliseconds,
          body: result.success ? result.data : null, error: result.error);

      // Auto-refresh token on 401 and retry
      if (result.isUnauthorized && requiresAuth) {
        final newToken = await _refreshAccessToken();

        if (newToken != null) {
          // Retry with new token
          final retryHeaders = await _getHeaders(includeAuth: true);
          final retryResponse = await http.put(
            uri,
            headers: retryHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          return _handleResponse(retryResponse, endpoint);
        } else {
          // Token refresh failed - trigger auth error callback
          onAuthenticationError?.call();
        }
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// DELETE request with automatic 401 token refresh
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      _logRequest('DELETE', uri.toString(), body: body);
      final stopwatch = Stopwatch()..start();
      final request = http.Request('DELETE', uri)
        ..headers.addAll(headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      final result = _handleResponse(response, endpoint);
      _logResponse('DELETE', endpoint, response.statusCode, stopwatch.elapsedMilliseconds,
          body: result.success ? result.data : null, error: result.error);

      // Auto-refresh token on 401 and retry
      if (result.isUnauthorized && requiresAuth) {
        final newToken = await _refreshAccessToken();

        if (newToken != null) {
          // Retry with new token
          final retryHeaders = await _getHeaders(includeAuth: true);
          final retryRequest = http.Request('DELETE', uri)
            ..headers.addAll(retryHeaders);

          if (body != null) {
            retryRequest.body = jsonEncode(body);
          }

          final retryStreamedResponse = await retryRequest.send();
          final retryResponse = await http.Response.fromStream(retryStreamedResponse);
          return _handleResponse(retryResponse, endpoint);
        } else {
          // Token refresh failed - trigger auth error callback
          onAuthenticationError?.call();
        }
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Multipart POST (for file uploads)
  Future<ApiResponse> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = requiresAuth ? await _getToken() : null;

      _logRequest('POST(multipart)', uri.toString(), body: 'fields=${fields.keys.toList()} files=${files.map((f) => f.filename).toList()}');
      final stopwatch = Stopwatch()..start();
      final request = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      final result = _handleResponse(response, endpoint);
      _logResponse('POST(multipart)', endpoint, response.statusCode, stopwatch.elapsedMilliseconds,
          body: result.success ? result.data : null, error: result.error);
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Upload failed. Please try again.',
        statusCode: 0,
      );
    }
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int statusCode;
  final RateLimitInfo? rateLimitInfo;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
    this.rateLimitInfo,
  });

  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() =>
      'ApiResponse(success: $success, statusCode: $statusCode, error: $error)';
}

/// Rate limit information
class RateLimitInfo {
  final int limit;
  final int remaining;
  final DateTime resetTime;

  RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.resetTime,
  });

  Duration get timeUntilReset {
    final now = DateTime.now();
    return resetTime.isAfter(now) ? resetTime.difference(now) : Duration.zero;
  }

  bool get isLimited => remaining <= 0;

  @override
  String toString() =>
      'RateLimitInfo(remaining: $remaining/$limit, reset: ${timeUntilReset.inSeconds}s)';
}

/// Debounce helper for UI interactions
class Debouncer {
  final Duration delay;
  Timer? _timer;
  bool _isDisposed = false;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Run action after delay, cancelling any pending action
  void run(VoidCallback action) {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!_isDisposed) action();
    });
  }

  /// Run async action after delay, returns future
  Future<T?> runAsync<T>(Future<T> Function() action) async {
    if (_isDisposed) return null;
    _timer?.cancel();
    final completer = Completer<T?>();
    _timer = Timer(delay, () async {
      if (!_isDisposed) {
        try {
          final result = await action();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      } else {
        completer.complete(null);
      }
    });
    return completer.future;
  }

  /// Check if there's a pending action
  bool get isPending => _timer?.isActive ?? false;

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose the debouncer
  void dispose() {
    _isDisposed = true;
    cancel();
  }
}

/// Search debouncer with longer delay optimized for search inputs
class SearchDebouncer extends Debouncer {
  SearchDebouncer() : super(delay: const Duration(milliseconds: 500));
}

/// Throttle helper to prevent rapid fire requests
class Throttler {
  final Duration delay;
  DateTime? _lastCall;

  Throttler({this.delay = const Duration(milliseconds: 500)});

  bool call(VoidCallback action) {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= delay) {
      _lastCall = now;
      action();
      return true;
    }
    return false;
  }
}
