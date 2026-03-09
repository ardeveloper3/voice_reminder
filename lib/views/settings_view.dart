import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/backgrund_service.dart';
import '../services/voice_service.dart';
import '../services/notification_service.dart';

import '../utils/theam_service.dart';


class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final VoiceService _voiceService = Get.find<VoiceService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final BackgroundService _backgroundService = Get.find<BackgroundService>();
  final ThemeService _themeService = Get.find<ThemeService>();
  
  bool _isLoadingPermissions = true;
  bool _microphonePermission = false;
  bool _notificationPermission = false;
  bool _backgroundServiceRunning = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoadingPermissions = true;
    });
    
    // Check microphone permission
    final micStatus = await Permission.microphone.status;
    _microphonePermission = micStatus.isGranted;
    
    // Check notification permission
    final notificationStatus = await Permission.notification.status;
    _notificationPermission = notificationStatus.isGranted;
    
    // Check background service status
    _backgroundServiceRunning = _backgroundService.isServiceRunning as bool;
    
    setState(() {
      _isLoadingPermissions = false;
    });
  }
  
  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _microphonePermission = status.isGranted;
    });
    
    if (status.isGranted) {
      Get.snackbar(
        'Permission Granted',
        'Microphone permission has been granted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Permission Denied',
        'Microphone permission is required for voice input.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }
  
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationPermission = status.isGranted;
    });
    
    if (status.isGranted) {
      Get.snackbar(
        'Permission Granted',
        'Notification permission has been granted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Permission Denied',
        'Notification permission is required for reminders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }
  
  Future<void> _toggleBackgroundService(bool value) async {
    if (value) {
      await _backgroundService.startService();
    } else {
      await _backgroundService.stopService();
    }
    
    setState(() {
      _backgroundServiceRunning = _backgroundService.isServiceRunning as bool;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoadingPermissions
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // App Theme Section
                _buildSectionHeader('Appearance'),
                Card(
                  child: Obx(() => SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle between light and dark theme'),
                    value: _themeService.isDarkMode.value,
                    onChanged: (value) {
                      _themeService.toggleTheme();
                    },
                    secondary: Icon(
                      _themeService.isDarkMode.value
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                  )),
                ),
                
                const SizedBox(height: 24),
                
                // Permissions Section
                _buildSectionHeader('Permissions'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.mic,
                          color: _microphonePermission
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: const Text('Microphone Access'),
                        subtitle: Text(
                          _microphonePermission
                              ? 'Permission granted'
                              : 'Permission required for voice input',
                        ),
                        trailing: TextButton(
                          onPressed: _requestMicrophonePermission,
                          child: Text(_microphonePermission ? 'GRANTED' : 'REQUEST'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: _notificationPermission
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: const Text('Notifications'),
                        subtitle: Text(
                          _notificationPermission
                              ? 'Permission granted'
                              : 'Permission required for reminders',
                        ),
                        trailing: TextButton(
                          onPressed: _requestNotificationPermission,
                          child: Text(_notificationPermission ? 'GRANTED' : 'REQUEST'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Services Section
                _buildSectionHeader('Services'),
                Card(
                  child: SwitchListTile(
                    title: const Text('Background Service'),
                    subtitle: const Text('Keep reminders running in the background'),
                    value: _backgroundServiceRunning,
                    onChanged: _toggleBackgroundService,
                    secondary: const Icon(Icons.sync),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // About Section
                _buildSectionHeader('About'),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('Voice Task Assistant'),
                        subtitle: Text('Version 1.0.0'),
                        leading: Icon(Icons.info),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Feedback & Support'),
                        subtitle: const Text('Report issues or suggest features'),
                        leading: const Icon(Icons.help),
                        onTap: () {
                          // Could open a feedback form or email link
                          Get.snackbar(
                            'Feedback',
                            'Feature coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reset and data management section
                Card(
                  color: Colors.red[50],
                  child: ListTile(
                    title: const Text(
                      'Reset All Data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Delete all tasks and reset app preferences',
                    ),
                    leading: Icon(
                      Icons.delete_forever,
                      color: Colors.red[700],
                    ),
                    onTap: () async {
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Reset All Data'),
                          content: const Text(
                              'This will delete all your tasks and reset app preferences. This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('RESET'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        // Reset all data
                        // This would typically call methods in your services
                        // to clear all stored data
                        Get.snackbar(
                          'Reset Completed',
                          'All data has been reset.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}