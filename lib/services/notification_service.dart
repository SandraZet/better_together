import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channels explicitly so sound/priority settings are
    // applied before FCM can auto-create them with wrong defaults.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      // Full-sound channel: "your idea is live now"
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'idea_notifications',
          'Idea Notifications',
          description: 'Get notified when your idea goes live',
          importance: Importance.high,
          playSound: true,
        ),
      );
      // Silent channel: "your idea got scheduled" (may arrive at night)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'idea_silent',
          'Idea Scheduled (Silent)',
          description: 'Quiet confirmation when your idea gets scheduled',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }

    // Request permission (will show system dialog on Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
      await _getToken();
    } else {
      debugPrint('❌ Notification permission denied');
    }

    // Clear badge when app opens
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    return await _getToken();
  }

  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token: $_fcmToken');
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Check if user has granted notification permission
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized;

    if (granted) {
      await _getToken();
    }

    return granted;
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message received:');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // Save scheduled idea notification to local storage
    if (message.data.containsKey('date') || message.data.containsKey('slot')) {
      await _saveScheduledNotification(message);
    }

    // Show local notification when app is in foreground
    if (message.notification != null) {
      final androidDetails = AndroidNotificationDetails(
        'idea_notifications',
        'Idea Notifications',
        channelDescription: 'Get notified when your ideas are scheduled',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: const Color(0xFFFF6B35),
        playSound: true,
        enableVibration: true,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
      );
    }
  }

  /// Save scheduled idea notification for profile page
  Future<void> _saveScheduledNotification(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledNotifications =
          prefs.getStringList('scheduled_notifications') ?? [];

      // Extract info from notification
      final title = message.notification?.title ?? 'Task scheduled';
      final body = message.notification?.body ?? '';
      final date = message.data['date'] ?? '';
      final slot = message.data['slot'] ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Save as delimited string: title|||body|||date|||slot|||timestamp
      final notificationData = [title, body, date, slot, timestamp].join('|||');
      scheduledNotifications.add(notificationData);

      await prefs.setStringList(
        'scheduled_notifications',
        scheduledNotifications,
      );
      debugPrint('💾 Saved scheduled notification: $title on $date $slot');
    } catch (e) {
      debugPrint('❌ Error saving scheduled notification: $e');
    }
  }

  /// Clear notification badge
  Future<void> clearBadge() async {
    // On Android, badge is cleared when user opens the notification or app
    // This is handled automatically by the system
    debugPrint('🔔 Badge cleared');
  }

  /// Check if user has opted in for idea notifications
  Future<bool> hasOptedInForIdeaNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('idea_notifications_opted_in') ?? false;
  }

  /// Save opt-in status
  Future<void> setIdeaNotificationsOptIn(bool optedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('idea_notifications_opted_in', optedIn);
  }
}
