import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class AuthService extends ChangeNotifier {
  bool isLoggedIn = false;
  String token = '';
  String refreshToken = '';
  String userId = '';
  int count = 0;

  // Initialize from SharedPreferences when app starts
  // Validates token and refreshes if needed
  Future<bool> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    refreshToken = prefs.getString('refreshToken') ?? '';
    userId = prefs.getString('userId') ?? '';
    
    // If we have tokens, validate them
    if (token.isNotEmpty && userId.isNotEmpty) {
      debugPrint('🔍 Validating stored token...');
      
      // Try to validate token by making a test API call
      final isValid = await _validateToken();
      
      if (isValid) {
        isLoggedIn = true;
        debugPrint('✅ Token is valid - userId: $userId');
    notifyListeners();
        return true;
      } else {
        // Token invalid, try to refresh
        debugPrint('⚠️ Token invalid, attempting refresh...');
        if (refreshToken.isNotEmpty) {
          final refreshResult = await refreshAccessToken();
          if (refreshResult['success'] == true) {
            isLoggedIn = true;
            debugPrint('✅ Token refreshed successfully - userId: $userId');
            notifyListeners();
            return true;
          } else {
            // Refresh failed, clear auth data
            debugPrint('❌ Token refresh failed, clearing auth data');
            await _clearAuthData();
            return false;
          }
        } else {
          // No refresh token, clear auth data
          debugPrint('❌ No refresh token available, clearing auth data');
          await _clearAuthData();
          return false;
        }
      }
    } else {
      // No tokens stored
      isLoggedIn = false;
      debugPrint('ℹ️ No stored tokens found');
      notifyListeners();
      return false;
    }
  }

  /// Validate token by making a test API call
  Future<bool> _validateToken() async {
    if (token.isEmpty || userId.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('${Endpoints.baseURL}auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Token is valid if we get 200
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        return false;
      } else {
        // Other error, assume token might be valid (network issue, etc.)
        // We'll let it pass and handle errors in actual API calls
        return true;
      }
    } catch (e) {
      // Network error - assume token might be valid
      // We'll handle actual errors in API calls
      debugPrint('⚠️ Token validation error (network): $e');
      return true; // Assume valid, will fail on actual API calls if not
    }
  }

  /// Parse error response from backend
  Map<String, dynamic> _parseErrorResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? data['error'] ?? 'An error occurred',
        'error': data['error'],
        'statusCode': response.statusCode,
        'lockUntil': data['lockUntil'],
        'remainingAttempts': data['remainingAttempts'],
        'retryAfter': data['retryAfter'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'statusCode': response.statusCode,
      };
    }
  }

  /// Check if account is locked
  bool _isAccountLocked(Map<String, dynamic> errorData) {
    return errorData['lockUntil'] != null ||
        errorData['message']?.toString().toLowerCase().contains('locked') ==
            true;
  }

  /// Check if rate limited
  bool _isRateLimited(Map<String, dynamic> errorData) {
    return errorData['retryAfter'] != null ||
        errorData['statusCode'] == 429 ||
        errorData['message']
                ?.toString()
                .toLowerCase()
                .contains('too many requests') ==
            true;
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.loginURL}');

    try {
    final response = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    print(response.body);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

        // Handle both old and new response formats
        userId = responseData['user']?['_id'] ??
            responseData['data']?['user']?['_id'] ??
            '';
        token = responseData['token'] ?? responseData['data']?['token'] ?? '';
        refreshToken = responseData['refreshToken'] ??
            responseData['data']?['refreshToken'] ??
            '';

      final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('userId', userId);
      isLoggedIn = true;
        notifyListeners();

        return {
          'success': true,
          'token': token,
          'refreshToken': refreshToken,
          'user': responseData['user'] ?? responseData['data']?['user'],
        };
    } else {
        final errorData = _parseErrorResponse(response);

        // Handle account lockout
        if (_isAccountLocked(errorData)) {
          final lockUntil = errorData['lockUntil'];
          String message =
              'Account is temporarily locked due to too many failed login attempts.';
          if (lockUntil != null) {
            try {
              final lockTime = DateTime.parse(lockUntil);
              final now = DateTime.now();
              if (lockTime.isAfter(now)) {
                final minutes = lockTime.difference(now).inMinutes;
                message += ' Please try again in $minutes minutes.';
              }
            } catch (e) {
              message += ' Please try again later.';
            }
          }
          return {
            'success': false,
            'message': message,
            'isLocked': true,
            'lockUntil': lockUntil,
          };
        }

        // Handle rate limiting
        if (_isRateLimited(errorData)) {
          final retryAfter = errorData['retryAfter'];
          String message =
              'Too many login attempts. Please wait a moment before trying again.';
          if (retryAfter != null) {
            message += ' Retry after $retryAfter seconds.';
          }
          return {
            'success': false,
            'message': message,
            'isRateLimited': true,
            'retryAfter': retryAfter,
          };
        }

        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid email or password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Facebook Sign-In for iOS/Android
  /// Sends access token to backend for authentication
  Future<Map<String, dynamic>> signInWithFacebookNative(
      String accessToken) async {
    try {
      final url = Uri.parse('${Endpoints.baseURL}auth/facebook/mobile');

      debugPrint('🔍 Sending Facebook access token to: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accessToken': accessToken,
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data['token'] != null) {
          final responseToken = data['token'] ?? data['data']?['token'];
          final responseRefreshToken =
              data['refreshToken'] ?? data['data']?['refreshToken'];
          final responseUserId =
              data['user']?['_id'] ?? data['data']?['user']?['_id'];

          if (responseToken != null && responseUserId != null) {
            // Store tokens
            this.token = responseToken;
            this.refreshToken = responseRefreshToken ?? '';
            this.userId = responseUserId;
            this.isLoggedIn = true;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', responseToken);
            if (responseRefreshToken != null) {
              await prefs.setString('refreshToken', responseRefreshToken);
            }
            await prefs.setString('userId', responseUserId);
            notifyListeners();

            debugPrint('✅ Facebook login successful - userId: $responseUserId');

            return {
              'success': true,
              'token': responseToken,
              'refreshToken': responseRefreshToken,
              'userId': responseUserId,
              'user': data['user'], // Return raw user data as Map
            };
          } else {
            return {
              'success': false,
              'message': 'Missing authentication tokens in response',
            };
          }
        } else {
          return {
            'success': false,
            'message':
                data['message'] ?? data['error'] ?? 'Authentication failed',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Facebook Sign-In Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> logoutWithFacebook() async {
    try {
      // Logout from Facebook
      // await FacebookAuth.instance.logOut();

      // Then perform regular logout
      return await logout();
    } catch (e) {
      debugPrint('Facebook Logout Error: $e');
      // Still perform regular logout even if Facebook logout fails
      return await logout();
    }
  }

  /// Get Google OAuth URL
  String getGoogleLoginUrl() {
    return '${Endpoints.baseURL}${Endpoints.googleLoginURL}';
  }

  /// Handle Google OAuth callback and extract tokens
  /// This is called when the OAuth callback is received
  Future<Map<String, dynamic>> handleGoogleCallback(
      Map<String, String> callbackData) async {
    try {
      // The backend should redirect with tokens in the callback
      // We need to extract them from the callback URL or make a request
      // For now, we'll check if the callback contains token information

      // If backend redirects with tokens in URL params or response
      final token = callbackData['token'];
      final refreshToken = callbackData['refreshToken'];
      final userId = callbackData['userId'];

      if (token != null && refreshToken != null && userId != null) {
        this.token = token;
        this.refreshToken = refreshToken;
        this.userId = userId;
        isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('userId', userId);
        notifyListeners();

        return {
          'success': true,
          'token': token,
          'refreshToken': refreshToken,
          'userId': userId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to extract tokens from callback',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error handling Google callback: ${e.toString()}',
      };
    }
  }

  /// Complete Google login after OAuth callback
  /// This fetches user data after successful OAuth
  Future<Map<String, dynamic>> completeGoogleLogin() async {
    try {
      // After OAuth callback, get user data
      final user = await getLoggedInUser();

      return {
        'success': true,
        'user': user,
        'token': token,
        'refreshToken': refreshToken,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to complete Google login: ${e.toString()}',
      };
    }
  }

  /// Native Google Sign-In for iOS/Android
  /// Sends ID token to backend for authentication
  /// Native Google Sign-In for iOS/Android
  /// Sends ID token to backend for authentication
  Future<Map<String, dynamic>> signInWithGoogleNative(String idToken) async {
    try {
      final url = Uri.parse('${Endpoints.baseURL}auth/google/mobile');

      debugPrint('🔍 Sending Google ID token to: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data['token'] != null) {
          final responseToken = data['token'] ?? data['data']?['token'];
          final responseRefreshToken =
              data['refreshToken'] ?? data['data']?['refreshToken'];
          final responseUserId =
              data['user']?['_id'] ?? data['data']?['user']?['_id'];

          if (responseToken != null && responseUserId != null) {
            // Store tokens
            this.token = responseToken;
            this.refreshToken = responseRefreshToken ?? '';
            this.userId = responseUserId;
            this.isLoggedIn = true;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', responseToken);
            if (responseRefreshToken != null) {
              await prefs.setString('refreshToken', responseRefreshToken);
            }
            await prefs.setString('userId', responseUserId);
            notifyListeners();

            debugPrint('✅ Google login successful - userId: $responseUserId');

            return {
              'success': true,
              'token': responseToken,
              'refreshToken': responseRefreshToken,
              'userId': responseUserId,
              'user': data[
                  'user'], // Return raw user data as Map, not Community object
            };
          } else {
            return {
              'success': false,
              'message': 'Missing authentication tokens in response',
            };
          }
        } else {
          return {
            'success': false,
            'message':
                data['message'] ?? data['error'] ?? 'Authentication failed',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Native Google Sign-In Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshAccessToken() async {
    if (refreshToken.isEmpty) {
      return {
        'success': false,
        'message': 'No refresh token available',
      };
    }

    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.refreshTokenURL}');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'refreshToken': refreshToken}),
        headers: {'Content-Type': 'application/json'},
      );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
        token = responseData['token'] ?? responseData['data']?['token'] ?? '';
        
        // Update refresh token if backend returns a new one (token rotation)
        final newRefreshToken = responseData['refreshToken'] ?? responseData['data']?['refreshToken'];
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          refreshToken = newRefreshToken;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await prefs.setString('refreshToken', refreshToken);
        }
        notifyListeners();

        return {
          'success': true,
          'token': token,
          'refreshToken': refreshToken,
        };
      } else {
        // Refresh token expired or invalid - logout user
        await _clearAuthData();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'requiresLogin': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Clear all authentication data
  Future<void> _clearAuthData() async {
      userId = '';
      token = '';
    refreshToken = '';
    isLoggedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    await prefs.remove('refreshToken');
      await prefs.remove('userId');
    notifyListeners();
  }

  Future<Map<String, dynamic>> logout({bool logoutAll = false}) async {
    final url = Uri.parse(
        '${Endpoints.baseURL}${logoutAll ? Endpoints.logoutAllURL : Endpoints.logoutURL}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (!logoutAll && refreshToken.isNotEmpty)
            'refreshToken': refreshToken,
        }),
      );

      // Clear auth data regardless of response status
      await _clearAuthData();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Logged out successfully',
        };
    } else {
        // Even if logout fails on server, we've cleared local data
        return {
          'success': true,
          'message': 'Logged out locally',
        };
      }
    } catch (e) {
      // Clear auth data even on error
      await _clearAuthData();
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.sendCode}');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      print(response.body);
      print(response.statusCode);
      print(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Verification code sent',
          'data': data['data']
        };
      } else {
        final errorData = _parseErrorResponse(response);

        // Handle rate limiting for email requests
        if (_isRateLimited(errorData)) {
          final retryAfter = errorData['retryAfter'];
          String message =
              'Too many email requests. Please wait before requesting another code.';
          if (retryAfter != null) {
            message += ' Retry after $retryAfter seconds.';
          }
        return {
          'success': false,
            'message': message,
            'isRateLimited': true,
            'retryAfter': retryAfter,
          };
        }

        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send verification code'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.verifyEmailCode}');

    print('Verifying email code - URL: $url');
    print('Endpoint: ${Endpoints.verifyEmailCode}');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'email': email, 'code': code}),
        headers: {'Content-Type': 'application/json'},
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email verified successfully',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Invalid or expired verification code'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Validate password according to backend requirements
  /// Requirements: Minimum 8 characters, at least one uppercase, one lowercase, one number
  static Map<String, dynamic> validatePassword(String password) {
    if (password.isEmpty) {
      return {
        'valid': false,
        'message': 'Password is required',
      };
    }

    if (password.length < 8) {
      return {
        'valid': false,
        'message': 'Password must be at least 8 characters long',
      };
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one uppercase letter',
      };
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one lowercase letter',
      };
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one number',
      };
    }

    return {
      'valid': true,
      'message': 'Password is valid',
    };
  }

  /// Validate email format
  static bool validateEmail(String email) {
    final emailPattern = r'^[^@]+@[^@]+\.[^@]+';
    final emailRegex = RegExp(emailPattern);
    return emailRegex.hasMatch(email);
  }

  Future<Map<String, dynamic>> register(User user) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.registerURL}');

    try {
    final response = await http.post(
      url,
      body: jsonEncode(user),
      headers: {'Content-Type': 'application/json'},
    );

      print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Handle both old and new response formats
        userId = data['user']?['_id'] ?? data['data']?['user']?['_id'] ?? '';
        token = data['token'] ?? data['data']?['token'] ?? '';
        refreshToken =
            data['refreshToken'] ?? data['data']?['refreshToken'] ?? '';

      final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('userId', userId);
      isLoggedIn = true;
        notifyListeners();

        return {
          'success': true,
          'token': token,
          'refreshToken': refreshToken,
          'user': Community.fromJson(data['user'] ?? data['data']?['user']),
        };
    } else {
        final errorData = _parseErrorResponse(response);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Community> getLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String

    final url = Uri.parse('${Endpoints.baseURL}auth/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String userId = data['data']['_id'];
      await prefs.setString('userId', userId);
      return Community.fromJson(data['data']);
    } else {
      throw Exception('Failed to load user info');
    }
  }

  Future<String> sendEmailCode({required email}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.sendCode}');
    final response = await http.post(url, body: {'email': email});
    if (response.statusCode == 200) {
      return 'Verification code sent';
    } else {
      throw Exception('Failed to find user email');
    }
  }

  /// Send password reset code
  Future<Map<String, dynamic>> sendPasswordResetCode({
    required String email,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}auth/forgot-password');

    print(url);
    try {
      final response = await http.post(
        url,
        body: jsonEncode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      print(response.body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Reset code sent',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to send reset code'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify password reset code
  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}auth/verify-reset-code');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'email': email, 'code': code}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Code verified',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Invalid reset code'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // Validate password before sending request
    final passwordValidation = validatePassword(newPassword);
    if (!passwordValidation['valid']) {
      return {
        'success': false,
        'message': passwordValidation['message'],
      };
    }

    final url = Uri.parse('${Endpoints.baseURL}auth/reset-password');

    try {
      final response = await http.post(
        url,
        body: jsonEncode(
            {'email': email, 'code': code, 'newPassword': newPassword}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

        // Handle both old and new response formats
        userId = data['user']?['_id'] ??
            data['user']?['id'] ??
            data['data']?['user']?['_id'] ??
            '';
        token = data['token'] ?? data['data']?['token'] ?? '';
        refreshToken =
            data['refreshToken'] ?? data['data']?['refreshToken'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('userId', userId);
        isLoggedIn = true;
        notifyListeners();

        return {
          'success': true,
          'message': 'Password reset successful',
          'token': token,
          'refreshToken': refreshToken,
          'user': data['user'] ?? data['data']?['user'],
        };
      } else {
        final errorData = _parseErrorResponse(response);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Community> updateUserMbti({required mbti}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'mbti': mbti}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['user']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserNativeLanguage({required natLang}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'native_language': natLang}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['user']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserLanguageToLearn({required langToLearn}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'language_to_learn': langToLearn}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['user']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserBloodType({required bloodType}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'bloodType': bloodType}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['user']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserName({required userName, required gender}) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/${userId}');
    final response = await http.put(
      url,
      body: json.encode({'name': userName, 'gender': gender}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      return Community.fromJson(data['user']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Community> updateUserBio({required String bio}) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$userId');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }
    
    final response = await http.put(
      url,
      body: json.encode({'bio': bio}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['user'] ?? data['data']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? errorData['message'] ?? 'Failed to update bio');
    }
  }

  Future<Community> updatePrivacySettings({
    required Map<String, bool> privacySettings,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$userId');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authentication required. Please login again.');
    }
    
    final response = await http.put(
      url,
      body: json.encode({'privacySettings': privacySettings}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Community.fromJson(data['user'] ?? data['data']);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? errorData['message'] ?? 'Failed to update privacy settings');
    }
  }

  Future<Community> updateUserHometown({
    required String city,
    required String country,
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$userId');

    final locationData = {
      'location': {
        'type': 'Point',
        'coordinates': [
          longitude ?? 0.0,
          latitude ?? 0.0,
        ],
        'formattedAddress': '$city, $country',
        'city': city,
        'country': country,
      }
    };

    final response = await http.put(
      url,
      body: jsonEncode(locationData),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('Response: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Empty response body');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format: $decoded');
      }

      // Ensure the 'user' key exists
      final userData = decoded['user'];
      if (userData == null || userData is! Map<String, dynamic>) {
        throw Exception(
            'Missing or invalid "user" field in response: $decoded');
      }

      return Community.fromJson(userData);
    } else {
      throw Exception(
          'Failed to update hometown: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Community>> getFollowersUser({required id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && token.isEmpty) {
      throw Exception('There is no token, please check');
    }

    final url = Uri.parse('${Endpoints.baseURL}auth/users/$id/followers');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Debug: Print the response structure
      debugPrint('🔍 Followers API Response: ${response.body}');
      debugPrint('🔍 Followers Response Keys: ${data.keys.toList()}');
      
      // Try different possible response structures
      List<dynamic>? followersList;
      
      // Check if data is wrapped in 'data' field (like other endpoints)
      if (data['data'] != null && data['data'] is List) {
        followersList = data['data'] as List<dynamic>;
        debugPrint('✅ Found followers in data.data: ${followersList.length} items');
      } 
      // Check if followers is directly in response
      else if (data['followers'] != null && data['followers'] is List) {
        followersList = data['followers'] as List<dynamic>;
        debugPrint('✅ Found followers in data.followers: ${followersList.length} items');
      }
      // Check if it's a success response with data
      else if (data['success'] == true && data['data'] != null) {
        if (data['data'] is List) {
          followersList = data['data'] as List<dynamic>;
          debugPrint('✅ Found followers in success.data: ${followersList.length} items');
        } else if (data['data']['followers'] != null) {
          followersList = data['data']['followers'] as List<dynamic>?;
          debugPrint('✅ Found followers in success.data.followers: ${followersList?.length ?? 0} items');
        }
      }
      
      if (followersList == null || followersList.isEmpty) {
        debugPrint('⚠️ No followers found or empty list');
        return <Community>[];
      }
      
      List<Community> followers =
          followersList.map((json) => Community.fromJson(json)).toList();

      debugPrint('✅ Successfully parsed ${followers.length} followers');
      return followers;
    } else {
      final errorData = json.decode(response.body);
      debugPrint('❌ Followers API Error: ${errorData.toString()}');
      throw Exception(errorData['error'] ?? errorData['message'] ?? 'Failed to load followers');
    }
  }

  Future<List<Community>> getFollowingsUser({required id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && token.isEmpty) {
      throw Exception('There is no token, please check');
    }

    final url = Uri.parse('${Endpoints.baseURL}auth/users/$id/following');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Debug: Print the response structure
      debugPrint('🔍 Followings API Response: ${response.body}');
      debugPrint('🔍 Followings Response Keys: ${data.keys.toList()}');
      
      // Try different possible response structures
      List<dynamic>? followingList;
      
      // Check if data is wrapped in 'data' field (like other endpoints)
      if (data['data'] != null && data['data'] is List) {
        followingList = data['data'] as List<dynamic>;
        debugPrint('✅ Found followings in data.data: ${followingList.length} items');
      } 
      // Check if following is directly in response
      else if (data['following'] != null && data['following'] is List) {
        followingList = data['following'] as List<dynamic>;
        debugPrint('✅ Found followings in data.following: ${followingList.length} items');
      }
      // Check if it's a success response with data
      else if (data['success'] == true && data['data'] != null) {
        if (data['data'] is List) {
          followingList = data['data'] as List<dynamic>;
          debugPrint('✅ Found followings in success.data: ${followingList.length} items');
        } else if (data['data']['following'] != null) {
          followingList = data['data']['following'] as List<dynamic>?;
          debugPrint('✅ Found followings in success.data.following: ${followingList?.length ?? 0} items');
        }
      }
      
      if (followingList == null || followingList.isEmpty) {
        debugPrint('⚠️ No followings found or empty list');
        return <Community>[];
      }
      
      List<Community> followings =
          followingList.map((json) => Community.fromJson(json)).toList();

      debugPrint('✅ Successfully parsed ${followings.length} followings');
      return followings;
    } else {
      final errorData = json.decode(response.body);
      debugPrint('❌ Followings API Error: ${errorData.toString()}');
      throw Exception(errorData['error'] ?? errorData['message'] ?? 'Failed to load followings');
    }
  }

  Future<void> uploadUserPhoto(String userId, List<File> imageFiles) async {
    final url =
        Uri.parse('${Endpoints.baseURL}${Endpoints.usersURL}/$userId/photo');
    final request = http.MultipartRequest('PUT', url);

    for (var imageFile in imageFiles) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
      } else {
        response.stream.transform(utf8.decoder).listen((value) {});
      }
    } catch (e) {}
  }
}

final authServiceProvider = ChangeNotifierProvider((ref) {
  final authService = AuthService();
  // initializeAuth() is called from SplashScreen to ensure proper async handling
  return authService;
});
final userProvider = FutureProvider<Community>((ref) async {
  try {
    return await ref.read(authServiceProvider).getLoggedInUser();
  } catch (e) {
    debugPrint('Error fetching user: $e');
    throw Exception('Unable to fetch user');
  }
});
