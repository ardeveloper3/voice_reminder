import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const String _channelId = 'voice_task_assistant_channel';
  static const String _channelName = 'Task Reminders';
  static const String _channelDesc = 'Notifications for task reminders';

  Future<NotificationService> init() async {
    try {
      // Request notification permissions
      await _requestPermission();

      // Initialize notification settings
      await _initNotifications();

      // Set up notification actions and categories
      await _setupActions();

      // Handle notification click
      _setupNotificationClickListener();

      debugPrint('Notification service initialized successfully');
      return this;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      return this;
    }
  }

  Future<void> _requestPermission() async {
    // Request notification permission
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initNotifications() async {
    // Initialize for Android
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings for all platforms
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _setupActions() async {
    // For Android
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    // For iOS
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupNotificationClickListener() {
    // Check if app was launched from a notification
    _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails()
        .then((details) {
      if (details != null && details.didNotificationLaunchApp) {
        _handleNotificationPayload(details.notificationResponse?.payload);
      }
    });
  }

  void _onNotificationTap(NotificationResponse? response) {
    _handleNotificationPayload(response?.payload);
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    // The payload contains the task ID
    Get.toNamed('/alarm', arguments: payload);
  }

  // Schedule a notification for a specific time
  Future<void> scheduleNotification(
      String id,
      String title,
      String body,
      DateTime scheduledTime,
      ) async {
    try {
      // Cancel any existing notification with the same ID
      await cancel(id);

      // Convert to TZ time
      final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Skip if the scheduled time is in the past
      if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Skipping notification for $title because the time is in the past');
        return;
      }

      // Create Android-specific notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );

      // Create iOS-specific notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      // Create the notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id.hashCode,
        title,
        body,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: id,  // Pass the task ID as the payload
      );

      debugPrint('Scheduled notification for $title at ${scheduledTime.toString()}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Show an immediate notification
  Future<void> showNotification(
      String id,
      String title,
      String body,
      ) async {
    try {
      // Create the notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        id.hashCode,
        title,
        body,
        notificationDetails,
        payload: id,  // Pass the task ID as the payload
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Cancel a notification by ID
  Future<void> cancel(String id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id.hashCode);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  // Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }
}
