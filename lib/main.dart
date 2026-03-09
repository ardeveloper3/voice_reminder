import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:voiceremider/services/backgrund_service.dart';
import 'package:voiceremider/services/notification_service.dart';
import 'package:voiceremider/services/storage_service.dart';
import 'package:voiceremider/services/voice_service.dart';
import 'package:voiceremider/utils/theam_service.dart';
import 'package:voiceremider/viewmodels/taskviewmodels.dart';

import 'views/splash_view.dart';
import 'views/home_view.dart';
import 'views/task_create_view.dart';
import 'views/task_detail_view.dart';
import 'views/settings_view.dart';
import 'views/alarm_view.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize time zones for scheduled notifications
  tz.initializeTimeZones();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize GetStorage
  await GetStorage.init();
  // Register dependencies in correct order
  // Register all services first
  Get.put(StorageService());
  Get.put(NotificationService());
  Get.put(VoiceService());
  Get.put(BackgroundService()); // <-- Add this line

  // Then register TaskViewModel (which depends on the services above)
  Get.put(TaskViewModel());

  runApp(VoiceTaskAssistantApp());
}

class VoiceTaskAssistantApp extends StatelessWidget {
  VoiceTaskAssistantApp({Key? key}) : super(key: key);

  // This allows us to access theme service before it's officially initialized
  final _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Voice Task Assistant',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: _themeService.themeMode,

      // Routes
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashView()),
        GetPage(name: '/home', page: () => const HomeView()),
        GetPage(name: '/task/create', page: () => const TaskCreateView()),
        GetPage(name: '/task/detail', page: () => const TaskDetailView()),
        GetPage(name: '/settings', page: () => const SettingsView()),
        GetPage(name: '/alarm', page: () => const AlarmView()),
      ],
    );
  }
}
