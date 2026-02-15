import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging (FCM) Push Notification Service
/// Handles notification permissions, token management, and message handling
///
/// Week 6 Bonus: Push Notifications using Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize FCM - request permissions and get token
  Future<void> initialize() async {
    try {
      // Request notification permissions (iOS, web, macOS)
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('FCM: User granted permission');

        // Get FCM token
        await _getToken();

        // Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('FCM: Token refreshed: $newToken');
          // TODO: Send updated token to your backend server
        });

        // Configure foreground message handling
        _configureForegroundMessages();

        // Handle messages that opened the app from terminated state
        await _handleInitialMessage();

        // Handle messages that opened the app from background
        _handleBackgroundMessageTap();
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('FCM: Error initializing: $e');
    }
  }

  /// Get the FCM token for this device
  Future<String?> _getToken() async {
    try {
      // For web, you need to provide a VAPID key from Firebase Console
      if (kIsWeb) {
        _fcmToken = await _messaging.getToken(
          vapidKey: 'YOUR_VAPID_KEY_HERE', // Replace with your VAPID key
        );
      } else {
        _fcmToken = await _messaging.getToken();
      }

      debugPrint('FCM: Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('FCM: Error getting token: $e');
      return null;
    }
  }

  /// Configure handling of foreground messages
  void _configureForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Foreground message received!');
      debugPrint('FCM: Title: ${message.notification?.title}');
      debugPrint('FCM: Body: ${message.notification?.body}');
      debugPrint('FCM: Data: ${message.data}');

      // Handle the message - you can show a local notification here
      _handleMessage(message);
    });
  }

  /// Handle a received message
  void _handleMessage(RemoteMessage message) {
    // Process the message based on data payload
    if (message.data.containsKey('type')) {
      switch (message.data['type']) {
        case 'task_reminder':
          debugPrint('FCM: Task reminder notification');
          break;
        case 'task_completed':
          debugPrint('FCM: Task completed notification');
          break;
        default:
          debugPrint('FCM: Unknown notification type');
      }
    }
  }

  /// Handle message that opened app from terminated state
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('FCM: App opened from terminated state via notification');
      _handleMessage(initialMessage);
    }
  }

  /// Handle message tap when app is in background
  void _handleBackgroundMessageTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: App opened from background via notification');
      _handleMessage(message);
    });
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('FCM: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('FCM: Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('FCM: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('FCM: Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe user to their personal notification channel
  Future<void> subscribeUserNotifications(String userId) async {
    await subscribeToTopic('user_$userId');
    await subscribeToTopic('all_users');
  }

  /// Unsubscribe user from notifications (on logout)
  Future<void> unsubscribeUserNotifications(String userId) async {
    await unsubscribeFromTopic('user_$userId');
  }
}

/// Top-level function for handling background messages
/// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.messageId}');
  // Handle background message processing here
  // Note: You cannot update UI from here
}
