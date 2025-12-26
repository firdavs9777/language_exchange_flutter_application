import 'dart:convert';
import 'dart:io';
import 'package:bananatalk_app/services/notification_api_client.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Handling background message: ${message.messageId}');
  debugPrint('📨 Title: ${message.notification?.title}');
  debugPrint('📨 Body: ${message.notification?.body}');
  debugPrint('📨 Data: ${message.data}');
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

  bool _isInitialized = false;
  BuildContext? _context;

  /// Initialize Firebase Cloud Messaging and request permissions
  Future<void> initialize({BuildContext? context}) async {
    if (_isInitialized) {
      debugPrint('⚠️ NotificationService already initialized');
      return;
    }

    _context = context;

    debugPrint('🔔 Initializing NotificationService...');

    try {
      // Initialize Firebase Messaging
      _fcm = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ Notification permissions granted');

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        await _getFCMToken();

        // Setup message handlers
        _setupMessageHandlers();

        // Check if app was opened from terminated state via notification
        final initialMessage = await _fcm!.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('🔔 App opened from terminated state via notification');
          // Delay navigation slightly to ensure app is fully initialized
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_context != null && _context!.mounted) {
              NotificationRouter.handleNotification(
                _context!,
                initialMessage.data,
              );
            }
          });
        }

        _isInitialized = true;
        debugPrint('✅ NotificationService initialized successfully');
      } else {
        debugPrint('❌ Notification permissions denied');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing NotificationService: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {
    debugPrint('📋 Requesting notification permissions...');

    final settings = await _fcm!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📋 Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    debugPrint('🔔 Initializing local notifications...');

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Chat messages and urgent notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    debugPrint('✅ Local notifications initialized');
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      // On iOS, we need to get APNS token first
      if (Platform.isIOS) {
        debugPrint('📱 Requesting APNS token for iOS...');

        // Request APNS token
        String? apnsToken = await _fcm!.getAPNSToken();

        // If APNS token is not available immediately, wait for it
        if (apnsToken == null) {
          debugPrint('⏳ Waiting for APNS token...');

          // Wait up to 10 seconds for APNS token
          int attempts = 0;
          while (apnsToken == null && attempts < 20) {
            await Future.delayed(const Duration(milliseconds: 500));
            apnsToken = await _fcm!.getAPNSToken();
            attempts++;
          }

          if (apnsToken != null) {
            debugPrint(
              '✅ APNS token received: ${apnsToken.substring(0, 20)}...',
            );
          } else {
            debugPrint('⚠️ APNS token not available after waiting');
          }
        } else {
          debugPrint(
            '✅ APNS token available: ${apnsToken.substring(0, 20)}...',
          );
        }
      }

      // Now get FCM token
      _fcmToken = await _fcm!.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // Listen for token refresh
      _fcm!.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _registerTokenWithBackend();
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message received: ${message.messageId}');
    debugPrint('📨 Title: ${message.notification?.title}');
    debugPrint('📨 Body: ${message.notification?.body}');
    debugPrint('📨 Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap when app was in background
  void _handleNotificationOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notification opened app: ${message.messageId}');
    debugPrint('📱 Context available: ${_context != null}');
    debugPrint('📱 Context mounted: ${_context?.mounted ?? false}');
    debugPrint('📱 Notification data: ${message.data}');

    if (_context != null && _context!.mounted) {
      debugPrint('📱 Calling NotificationRouter...');
      NotificationRouter.handleNotification(_context!, message.data);
    } else {
      debugPrint('❌ Cannot navigate: context is null or not mounted');
    }
  }

  /// Handle notification tap from local notification
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');

    if (response.payload != null && _context != null && _context!.mounted) {
      try {
        // Parse the JSON string payload back to Map
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        debugPrint('📱 Navigating with data: $data');
        NotificationRouter.handleNotification(_context!, data);
      } catch (e) {
        debugPrint('❌ Error handling notification tap: $e');
        debugPrint('Payload was: ${response.payload}');
      }
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Chat messages and urgent notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'BanaTalk',
        message.notification?.body ?? '',
        details,
        payload: jsonEncode(message.data), // Encode as proper JSON
      );
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend([String? userId]) async {
    if (_fcmToken == null) {
      debugPrint('⚠️ No FCM token available for registration');
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
        debugPrint('⚠️ No userId available, skipping token registration');
        return;
      }

      final deviceId = await _getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';

      debugPrint('📤 Registering token with backend for user: $userIdToUse');
      debugPrint('📤 FCM Token: ${_fcmToken!.substring(0, 50)}...');
      debugPrint('📤 Device ID: $deviceId');
      debugPrint('📤 Platform: $platform');

      final result = await _apiClient.registerToken(
        _fcmToken!,
        platform,
        deviceId,
      );

      if (result['success'] == true) {
        debugPrint('✅ Token registered with backend successfully!');
      } else {
        debugPrint('❌ Failed to register token: ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error registering token with backend: $e');
    }
  }

  /// Register token with backend (public method called after login)
  Future<void> registerToken(String userId) async {
    debugPrint('🔑 Registering token for user: $userId');

    // Wait a bit to ensure FCM token is available
    if (_fcmToken == null) {
      debugPrint('⏳ FCM token not ready yet, waiting...');
      await Future.delayed(const Duration(seconds: 1));
    }

    if (_fcmToken == null) {
      debugPrint('❌ FCM token still not available after waiting');
      return;
    }

    await _registerTokenWithBackend(userId);
  }

  /// Remove token from backend (called on logout)
  Future<void> removeToken() async {
    try {
      final deviceId = await _getDeviceId();

      debugPrint('📤 Removing token from backend...');
      final result = await _apiClient.removeToken(deviceId);

      if (result['success'] == true) {
        debugPrint('✅ Token removed from backend');
        _fcmToken = null;

        // Clear local token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_token');
      } else {
        debugPrint('❌ Failed to remove token: ${result['message']}');
      }
    } catch (e) {
      debugPrint('⚠️ Error removing token (may be already logged out): $e');
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
    if (Platform.isIOS && _fcm != null) {
      try {
        await _fcm!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('🔔 Badge count updated: $count');
      } catch (e) {
        debugPrint('❌ Error updating badge count: $e');
      }
    }
  }

  /// Clear app badge (set to 0)
  Future<void> clearBadge() async {
    // Badge will be managed by the backend via notification payloads
    // iOS clears badge when notifications are read
    debugPrint('🔔 Badge clear requested (handled by notification system)');
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
    debugPrint('🔔 Opening notification settings...');
    // Implementation will be in the UI layer using app_settings package
  }

  /// Set context for navigation
  void setContext(BuildContext context) {
    _context = context;
  }
}
