import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class BackgroundService extends GetxService {
  static const String _serviceName = 'voice_task_assistant_bg';

  Future<BackgroundService> init() async {
    try {
      // Request necessary permissions
      await _requestPermissions();

      // Initialize the background service
      await _initBackgroundService();

      debugPrint('Background service initialized successfully');
      return this;
    } catch (e) {
      debugPrint('Error initializing background service: $e');
      return this;
    }
  }

  Future<void> _requestPermissions() async {
    // Request battery optimization exemption for reliable background execution
    await Permission.ignoreBatteryOptimizations.request();

    // Request notification permission
    await Permission.notification.request();
  }

  Future<void> _initBackgroundService() async {
    final service = FlutterBackgroundService();

    // Configure the service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundOnStart, // ✅ renamed to avoid conflict
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: 'voice_task_assistant_bg_channel',
        initialNotificationTitle: 'Voice Task Assistant',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: backgroundOnStart, // ✅ renamed here too
        onBackground: onIosBackground,
      ),
    );

    // Start the service
    await service.startService();
  }

  // Background service entry point (renamed to avoid conflict with GetxService.onStart)
  @pragma('vm:entry-point')
  static void backgroundOnStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Main background task loop
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkTaskReminders(service);
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  // Check for task reminders in the background
  static Future<void> _checkTaskReminders(ServiceInstance service) async {
    try {
      debugPrint('Checking task reminders in background...');

      // Update the service notification to show it's active
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Voice Task Assistant",
          content: "Monitoring tasks - ${DateTime.now().toString().substring(11, 16)}",
        );
      }
    } catch (e) {
      debugPrint('Error checking task reminders: $e');
    }
  }

  // Update a task in the background monitoring
  Future<void> updateTaskInBackground(Task task) async {
    try {
      final service = FlutterBackgroundService();

      // Send task data to background service
      service.invoke('updateTask', {
        'taskId': task.id,
        'title': task.title,
        'reminderTime': task.reminderTime.millisecondsSinceEpoch,
        'isCompleted': task.isCompleted,
      });
    } catch (e) {
      debugPrint('Error updating task in background: $e');
    }
  }

  // Remove a task from background monitoring
  Future<void> removeTaskFromBackground(String taskId) async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('removeTask', {
        'taskId': taskId,
      });
    } catch (e) {
      debugPrint('Error removing task from background: $e');
    }
  }

  // Start the background service
  Future<void> startService() async {
    try {
      final service = FlutterBackgroundService();
      await service.startService();
    } catch (e) {
      debugPrint('Error starting background service: $e');
    }
  }

  // Stop the background service
  Future<void> stopService() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }

  // Check if the service is running
  Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      debugPrint('Error checking service status: $e');
      return false;
    }
  }
}
