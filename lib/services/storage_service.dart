import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

class StorageService extends GetxService {
  static const String _tasksBoxName = 'tasks';
  late Box<Map<dynamic, dynamic>> _tasksBox;

  Future<StorageService> init() async {
    try {
      // Open the tasks box
      _tasksBox = await Hive.openBox<Map<dynamic, dynamic>>(_tasksBoxName);
      debugPrint('Storage service initialized successfully');
      return this;
    } catch (e) {
      debugPrint('Error initializing storage service: $e');
      rethrow;
    }
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    try {
      final taskMaps = _tasksBox.values.toList();

      return taskMaps.map((taskMap) {
        // Convert dynamic map to proper Map<String, dynamic>
        final Map<String, dynamic> convertedMap = {};
        taskMap.forEach((key, value) {
          convertedMap[key.toString()] = value;
        });

        return Task.fromMap(convertedMap);
      }).toList();
    } catch (e) {
      debugPrint('Error getting all tasks: $e');
      return [];
    }
  }

  // Add a task
  Future<void> addTask(Task task) async {
    try {
      final taskMap = task.toMap();
      await _tasksBox.put(task.id, taskMap);
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  // Get a task by ID
  Future<Task?> getTask(String id) async {
    try {
      final taskMap = _tasksBox.get(id);
      if (taskMap == null) {
        return null;
      }

      // Convert dynamic map to proper Map<String, dynamic>
      final Map<String, dynamic> convertedMap = {};
      taskMap.forEach((key, value) {
        convertedMap[key.toString()] = value;
      });

      return Task.fromMap(convertedMap);
    } catch (e) {
      debugPrint('Error getting task: $e');
      return null;
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      final taskMap = task.toMap();
      await _tasksBox.put(task.id, taskMap);
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    try {
      await _tasksBox.delete(id);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Clear all tasks
  Future<void> clearAllTasks() async {
    try {
      await _tasksBox.clear();
    } catch (e) {
      debugPrint('Error clearing tasks: $e');
      rethrow;
    }
  }

  // Close the box when the app is closed
  Future<void> close() async {
    await _tasksBox.close();
  }
}