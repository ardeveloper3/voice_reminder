import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/task_model.dart';

import '../services/voice_service.dart';
import '../viewmodels/taskviewmodels.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AlarmView extends StatefulWidget {
  const AlarmView({Key? key}) : super(key: key);

  @override
  _AlarmViewState createState() => _AlarmViewState();
}

class _AlarmViewState extends State<AlarmView> with SingleTickerProviderStateMixin {
  final TaskViewModel _taskViewModel = Get.find<TaskViewModel>();
  final VoiceService _voiceService = Get.find<VoiceService>();
  
  late Task? _task;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    
    // Keep screen on during alarm
    WakelockPlus.enable();


    // Setup pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseController.repeat(reverse: true);
    
    // Get task ID from route arguments
    final String taskId = Get.arguments as String;
    _loadTask(taskId);
  }
  
  @override
  void dispose() {
    // Allow screen to turn off again
    WakelockPlus.disable();
    
    // Stop speech if still playing
    if (_isPlaying) {
      _voiceService.stopSpeaking();
    }
    
    _pulseController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTask(String taskId) async {
    _task = _taskViewModel.getTaskById(taskId);
    
    if (_task == null) {
      // Task not found, return to previous screen
      Get.back();
      return;
    }
    
    // Play voice announcement if enabled
    if (_task!.isVoiceReminder) {
      _playVoiceAnnouncement();
    }
    
    // Update UI
    setState(() {});
  }
  
  Future<void> _playVoiceAnnouncement() async {
    if (_task == null) return;
    
    setState(() {
      _isPlaying = true;
    });
    
    final String announcement = "It's time for: ${_task!.title}";
    
    // Play the announcement
    await _voiceService.speak(announcement);
    
    setState(() {
      _isPlaying = false;
    });
  }
  
  void _snoozeTask() async {
    if (_task == null) return;
    
    // Snooze for 10 minutes
    final DateTime newReminderTime = DateTime.now().add(const Duration(minutes: 10));
    
    try {
      await _taskViewModel.snoozeTask(_task!.id, newReminderTime);
      Get.back(); // Close alarm view
      
      Get.snackbar(
        'Task Snoozed',
        'Reminder set for 10 minutes from now',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to snooze task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }
  
  void _completeTask() async {
    if (_task == null) return;
    
    try {
      await _taskViewModel.toggleTaskCompletion(_task!.id, true);
      Get.back(); // Close alarm view
      
      Get.snackbar(
        'Task Completed',
        'Task marked as complete',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete task: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time display
                    Text(
                      TimeOfDay.now().format(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Task icon with pulse animation
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Task title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _task!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Task description if available
                    if (_task!.description != null && _task!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _task!.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Voice announcement indicator
                    if (_isPlaying)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volume_up,
                            color: Colors.white70,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Speaking...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Snooze button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _snoozeTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SNOOZE (10 MIN)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Complete button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _completeTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'COMPLETE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Dismiss button
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text(
                  'DISMISS',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
