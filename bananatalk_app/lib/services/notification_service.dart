import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bananatalk_app/services/callkit_service.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Top-level function for handling background messages.
/// Shows native CallKit/full-screen call UI for incoming calls.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final type = message.data['type']?.toString().toLowerCase();

  if (type == 'incoming_call') {
    final callerName = message.data['callerName'] ?? 'Unknown';
    final callerAvatar = message.data['callerProfilePicture'] ?? message.data['callerAvatar'];
    final callType = message.data['callType'] ?? 'audio';
    final callId = message.data['callId'] ?? '';

    // Use flutter_callkit_incoming for native call UI on both platforms.
    // On iOS this triggers CallKit (works on lock screen) — except in China
    // where MIIT regulations prohibit CallKit.
    // On Android this shows a full-screen activity (no permission issues).
    if (CallKitService.isCallKitAllowed) {
      final callKitService = CallKitService();
      await callKitService.showIncomingCall(
        callId: callId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        isVideo: callType == 'video',
      );
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationApiClient _apiClient = NotificationApiClient();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Track current user ID to ensure token refresh registers with correct user
  String? _currentUserId;

  bool _isInitialized = false;
  BuildContext? _context;

  /// Initialize Firebase Cloud Messaging and request permissions
  Future<void> initialize({BuildContext? context}) async {
    if (_isInitialized) {
      return;
    }

    _context = context;


    try {
      // Initialize Firebase Messaging
      _fcm = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // Initialize local notifications
        await _initializeLocalNotifications();

        // IMPORTANT: Disable Firebase auto-display for foreground messages
        // We handle foreground notifications manually to filter out chat messages
        await _fcm!.setForegroundNotificationPresentationOptions(
          alert: false,  // Don't auto-show banner (we show via local notifications)
          badge: true,   // Allow badge updates
          sound: false,  // Don't auto-play sound (we play via local notifications)
        );

        // Get FCM token
        await _getFCMToken();

        // Setup message handlers
        _setupMessageHandlers();

        // Check if app was opened from terminated state via notification
        final initialMessage = await _fcm!.getInitialMessage();
        if (initialMessage != null) {
          // Delay navigation to ensure app and GoRouter are fully initialized
          Future.delayed(const Duration(milliseconds: 1000), () {
            // Use goRouter directly - no context needed
            NotificationRouter.handleNotification(null, initialMessage.data);
          });
        }

        _isInitialized = true;
      } else {
      }
    } catch (e, stackTrace) {
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {

    final settings = await _fcm!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings with foreground notification presentation
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Enable foreground notification presentation
      notificationCategories: [],
      onDidReceiveLocalNotification: (id, title, body, payload) {
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Chat messages and urgent notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      await androidPlugin?.createNotificationChannel(channel);

      // Dedicated channel for incoming calls with full-screen intent
      const callChannel = AndroidNotificationChannel(
        'incoming_calls_channel',
        'Incoming Calls',
        description: 'Incoming voice and video call alerts',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );
      await androidPlugin?.createNotificationChannel(callChannel);
    }

  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      // On iOS, we need to get APNS token first
      if (Platform.isIOS) {

        // Request APNS token
        String? apnsToken = await _fcm!.getAPNSToken();

        // If APNS token is not available immediately, wait for it
        if (apnsToken == null) {

          // Wait up to 10 seconds for APNS token
          int attempts = 0;
          while (apnsToken == null && attempts < 20) {
            await Future.delayed(const Duration(milliseconds: 500));
            apnsToken = await _fcm!.getAPNSToken();
            attempts++;
          }

          if (apnsToken != null) {
          } else {
          }
        } else {
        }
      }

      // Now get FCM token
      _fcmToken = await _fcm!.getToken();

      if (_fcmToken != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // Listen for token refresh
      _fcm!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        // Use stored currentUserId to ensure we register with correct user after account switch
        if (_currentUserId != null) {
          _registerTokenWithBackend(_currentUserId);
        } else {
        }
      });
    } catch (e) {
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
  }

  // Track processed message IDs to prevent duplicates
  final Set<String> _processedMessageIds = {};

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final messageId = message.messageId ?? '${message.hashCode}';


    // Prevent duplicate processing
    if (_processedMessageIds.contains(messageId)) {
      return;
    }
    _processedMessageIds.add(messageId);

    // Clean up old message IDs (keep last 100)
    if (_processedMessageIds.length > 100) {
      _processedMessageIds.remove(_processedMessageIds.first);
    }

    final notificationType = message.data['type']?.toString().toLowerCase();

    // Don't show local notification for chat messages when app is in foreground
    // The socket already handles real-time message delivery
    if (notificationType == 'chat_message') {
      return;
    }

    // Incoming calls in foreground are handled by the socket → IncomingCallScreen.
    // Don't show a duplicate notification banner.
    if (notificationType == 'incoming_call') {
      return;
    }

    // Show local notification for other notification types
    await _showLocalNotification(message);
  }

  /// Handle notification tap when app was in background
  void _handleNotificationOpenedApp(RemoteMessage message) {

    // Use goRouter directly - no context needed
    NotificationRouter.handleNotification(null, message.data);
  }

  /// Handle notification tap from local notification
  void _handleNotificationTap(NotificationResponse response) {

    if (response.payload != null) {
      try {
        // Parse the JSON string payload back to Map
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        // Use goRouter directly - no context needed
        NotificationRouter.handleNotification(null, data);
      } catch (e) {
      }
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Get sender's image URL from notification or data
      final imageUrl = message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl ??
          message.data['imageUrl'];


      // Prepare notification details with sender's profile picture
      AndroidNotificationDetails androidDetails;
      DarwinNotificationDetails iosDetails;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Download and use the sender's profile picture
        final largeIcon = await _downloadAndSaveImage(imageUrl);

        androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Chat messages and urgent notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          largeIcon: largeIcon != null ? FilePathAndroidBitmap(largeIcon) : null,
          styleInformation: largeIcon != null
              ? BigTextStyleInformation(
                  message.notification?.body ?? '',
                  htmlFormatBigText: false,
                  contentTitle: message.notification?.title ?? 'BanaTalk',
                  htmlFormatContentTitle: false,
                )
              : null,
        );

        // For iOS, we use attachment if image is available
        List<DarwinNotificationAttachment>? attachments;
        if (largeIcon != null) {
          attachments = [
            DarwinNotificationAttachment(largeIcon),
          ];
        }

        iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
          attachments: attachments,
        );
      } else {
        // Default notification without image
        androidDetails = const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Chat messages and urgent notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        );
      }


      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'BanaTalk',
        message.notification?.body ?? '',
        details,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
    }
  }

  /// Download image and save to temporary file for notification
  Future<String?> _downloadAndSaveImage(String imageUrl) async {
    try {

      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend([String? userId]) async {
    if (_fcmToken == null) {
      return;
    }

    try {
      // Use provided userId or get from SharedPreferences
      String? userIdToUse = userId;

      if (userIdToUse == null) {
        final prefs = await SharedPreferences.getInstance();
        userIdToUse = prefs.getString('userId');
      }

      if (userIdToUse == null) {
        return;
      }

      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';


      final result = await _apiClient.registerToken(
        _fcmToken!,
        platform,
        deviceId,
      );

      if (result['success'] == true) {
      } else {
      }
    } catch (e) {
    }
  }

  /// Register token with backend (public method called after login)
  Future<void> registerToken(String userId) async {

    // Store the current user ID for token refresh events
    _currentUserId = userId;

    // Wait a bit to ensure FCM token is available
    if (_fcmToken == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    if (_fcmToken == null) {
      return;
    }

    await _registerTokenWithBackend(userId);
  }

  /// Remove token from backend (called on logout)
  Future<void> removeToken() async {
    try {
      final deviceId = await _getDeviceId();

      final result = await _apiClient.removeToken(deviceId);

      if (result['success'] == true) {
        _fcmToken = null;
        // Clear current user ID to prevent token refresh registering with old user
        _currentUserId = null;

        // Clear local token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');
      } else {
      }
    } catch (e) {
      // Clear current user ID even on error
      _currentUserId = null;
      // Don't throw error on logout - token might already be removed
    }
  }

  /// Get unique device ID
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }

    return 'unknown_device';
  }

  /// Get device ID (public method)
  Future<String> getDeviceId() async {
    return await _getDeviceId();
  }

  /// Update badge count (iOS)
  Future<void> updateBadgeCount(int count) async {
    // Badge count is managed via local notifications plugin
    // The actual badge update happens through FlutterLocalNotificationsPlugin
  }

  /// Clear app badge (set to 0)
  Future<void> clearBadge() async {
    // Badge will be managed by the backend via notification payloads
    // iOS clears badge when notifications are read
  }

  /// Cancel the ongoing incoming-call notification (Android full-screen intent)
  Future<void> cancelCallNotification() async {
    await _localNotifications.cancel(9999);
  }

  /// Check notification permission status
  Future<bool> hasPermission() async {
    if (_fcm == null) return false;
    final settings = await _fcm!.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Open app notification settings
  Future<void> openSettings() async {
    // This will be handled by app_settings package
    // Implementation will be in the UI layer using app_settings package
  }

  /// Set context for navigation
  void setContext(BuildContext context) {
    _context = context;
  }
}
