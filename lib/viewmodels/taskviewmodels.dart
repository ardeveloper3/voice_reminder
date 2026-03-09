import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../services/backgrund_service.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart';
import '../services/notification_service.dart';

class TaskViewModel extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final VoiceService _voiceService = Get.find<VoiceService>();
  final NotificationService _notificationService = Get.find<NotificationService>();
  final BackgroundService _backgroundService = Get.find<BackgroundService>();

  // Observable task lists
  final RxList<Task> _tasks = <Task>[].obs;
  final RxList<Task> _todayTasks = <Task>[].obs;
  final RxList<Task> _upcomingTasks = <Task>[].obs;
  final RxList<Task> _completedTasks = <Task>[].obs;
  final RxList<Task> _searchResults = <Task>[].obs;
  final RxString _searchQuery = ''.obs;

  // Getters for the observable lists
  List<Task> get allTasks => _tasks.toList();
  List<Task> get todayTasks => _todayTasks.toList();
  List<Task> get upcomingTasks => _upcomingTasks.toList();
  List<Task> get completedTasks => _completedTasks.toList();
  List<Task> get searchResults => _searchResults.toList();
  String get searchQuery => _searchQuery.value;

  Future<TaskViewModel> init() async {
    // Load tasks from storage
    await _loadTasks();
    return this;
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _storageService.getAllTasks();
      _tasks.assignAll(tasks);
      _filterTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  // Filter tasks into different categories
  void _filterTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Filter tasks
    List<Task> todayTaskList = [];
    List<Task> upcomingTaskList = [];
    List<Task> completedTaskList = [];

    for (final task in _tasks) {
      if (task.isCompleted) {
        completedTaskList.add(task);
        continue;
      }

      // Handle recurring tasks
      final DateTime relevantReminderTime = task.repetition != null &&
          task.repetition != 'none' &&
          task.reminderTime.isBefore(now)
          ? task.getNextReminderTime()
          : task.reminderTime;

      final taskDate = DateTime(
        relevantReminderTime.year,
        relevantReminderTime.month,
        relevantReminderTime.day,
      );

      if (taskDate.isAtSameMomentAs(today)) {
        todayTaskList.add(task);
      } else {
        upcomingTaskList.add(task);
      }
    }

    // Sort tasks by date and time
    todayTaskList.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    upcomingTaskList.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    completedTaskList.sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

    // Update the observable lists
    _todayTasks.assignAll(todayTaskList);
    _upcomingTasks.assignAll(upcomingTaskList);
    _completedTasks.assignAll(completedTaskList);
  }

  // Add a new task
  Future<void> addTask(
      String title,
      String? description,
      DateTime reminderTime,
      String repetition,
      bool isVoiceReminder,
      String? customSoundPath,
      ) async {
    try {
      final task = Task(
        title: title,
        description: description,
        reminderTime: reminderTime,
        repetition: repetition,
        isVoiceReminder: isVoiceReminder,
        customSoundPath: customSoundPath,
      );

      // Save to storage
      await _storageService.addTask(task);

      // Add to observable list
      _tasks.add(task);

      // Schedule notification
      await _scheduleTaskNotification(task);

      // Update background service
      await _backgroundService.updateTaskInBackground(task);

      // Update filtered lists
      _filterTasks();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  // Get a task by ID
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update an existing task
  Future<void> updateTask(
      String id,
      String title,
      String? description,
      DateTime reminderTime,
      String repetition,
      bool isVoiceReminder,
      String? customSoundPath,
      ) async {
    try {
      // Find the task
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) {
        throw Exception('Task not found');
      }

      // Get the current task
      final currentTask = _tasks[taskIndex];

      // Update the task
      final updatedTask = currentTask.copyWith(
        title: title,
        description: description,
        reminderTime: reminderTime,
        repetition: repetition,
        isVoiceReminder: isVoiceReminder,
        customSoundPath: customSoundPath,
      );

      // Save to storage
      await _storageService.updateTask(updatedTask);

      // Cancel previous notification
      await _notificationService.cancel(id);

      // Schedule new notification
      await _scheduleTaskNotification(updatedTask);

      // Update background service
      await _backgroundService.updateTaskInBackground(updatedTask);

      // Update in observable list
      _tasks[taskIndex] = updatedTask;

      // Update filtered lists
      _filterTasks();
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    try {
      // Find the task
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) {
        throw Exception('Task not found');
      }

      // Delete from storage
      await _storageService.deleteTask(id);

      // Cancel notification
      await _notificationService.cancel(id);

      // Remove from background service
      await _backgroundService.removeTaskFromBackground(id);

      // Remove from observable list
      _tasks.removeAt(taskIndex);

      // Update filtered lists
      _filterTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    try {
      // Find the task
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) {
        throw Exception('Task not found');
      }

      // Get the current task
      final currentTask = _tasks[taskIndex];

      // Update the task
      final updatedTask = currentTask.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );

      // Save to storage
      await _storageService.updateTask(updatedTask);

      // If completed, cancel notification
      if (isCompleted) {
        await _notificationService.cancel(id);
      } else {
        // Otherwise, reschedule notification
        await _scheduleTaskNotification(updatedTask);
      }

      // Update background service
      await _backgroundService.updateTaskInBackground(updatedTask);

      // Update in observable list
      _tasks[taskIndex] = updatedTask;

      // Update filtered lists
      _filterTasks();
    } catch (e) {
      debugPrint('Error toggling task completion: $e');
      rethrow;
    }
  }

  // Snooze a task
  Future<void> snoozeTask(String id, DateTime newReminderTime) async {
    try {
      // Find the task
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) {
        throw Exception('Task not found');
      }

      // Get the current task
      final currentTask = _tasks[taskIndex];

      // Update the task with the new reminder time
      // For repeating tasks, we're only snoozing the current instance
      final updatedTask = currentTask.copyWith(
        reminderTime: newReminderTime,
      );

      // Save to storage
      await _storageService.updateTask(updatedTask);

      // Cancel previous notification
      await _notificationService.cancel(id);

      // Schedule new notification
      await _scheduleTaskNotification(updatedTask);

      // Update background service
      await _backgroundService.updateTaskInBackground(updatedTask);

      // Update in observable list
      _tasks[taskIndex] = updatedTask;

      // Update filtered lists
      _filterTasks();
    } catch (e) {
      debugPrint('Error snoozing task: $e');
      rethrow;
    }
  }

  // Schedule a notification for a task
  Future<void> _scheduleTaskNotification(Task task) async {
    if (task.isCompleted) return;

    // Determine the reminder time
    final DateTime reminderTime = task.repetition != null &&
        task.repetition != 'none' &&
        task.reminderTime.isBefore(DateTime.now())
        ? task.getNextReminderTime()
        : task.reminderTime;

    // Schedule the notification
    await _notificationService.scheduleNotification(
      task.id,
      'Task Reminder',
      task.title,
      reminderTime,
    );
  }

  // Search tasks
  void searchTasks(String query) {
    _searchQuery.value = query;

    if (query.trim().isEmpty) {
      _searchResults.clear();
      return;
    }

    final results = _tasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = task.description != null &&
          task.description!.toLowerCase().contains(query.toLowerCase());
      return titleMatch || descriptionMatch;
    }).toList();

    // Sort results: incomplete tasks first, then by date
    results.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.reminderTime.compareTo(b.reminderTime);
    });

    _searchResults.assignAll(results);
  }

  // Use voice input for searching
  Future<void> startVoiceSearch() async {
    try {
      final success = await _voiceService.startListening();
      if (!success) {
        Get.snackbar(
          'Voice Recognition',
          'Failed to start voice recognition',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    } catch (e) {
      debugPrint('Error starting voice search: $e');
    }
  }
}