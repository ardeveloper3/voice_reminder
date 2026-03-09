import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  String? description;
  DateTime reminderTime;
  String? repetition; // 'none', 'daily', 'weekly', 'monthly'
  bool isCompleted;
  bool isVoiceReminder;
  String? customSoundPath;
  final DateTime createdAt;
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.reminderTime,
    this.repetition,
    this.isCompleted = false,
    this.isVoiceReminder = false,
    this.customSoundPath,
    DateTime? createdAt,
    this.completedAt,
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Convert Task to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminderTime': reminderTime.millisecondsSinceEpoch,
      'repetition': repetition ?? 'none',
      'isCompleted': isCompleted,
      'isVoiceReminder': isVoiceReminder,
      'customSoundPath': customSoundPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  // Create a Task from a map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      reminderTime: DateTime.fromMillisecondsSinceEpoch(map['reminderTime']),
      repetition: map['repetition'],
      isCompleted: map['isCompleted'] ?? false,
      isVoiceReminder: map['isVoiceReminder'] ?? false,
      customSoundPath: map['customSoundPath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }

  // Create a copy of the task with updated fields
  Task copyWith({
    String? title,
    String? description,
    DateTime? reminderTime,
    String? repetition,
    bool? isCompleted,
    bool? isVoiceReminder,
    String? customSoundPath,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      repetition: repetition ?? this.repetition,
      isCompleted: isCompleted ?? this.isCompleted,
      isVoiceReminder: isVoiceReminder ?? this.isVoiceReminder,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Check if the task is due (overdue and not completed)
  bool get isDue {
    final now = DateTime.now();

    if (isCompleted) return false;

    if (repetition == null || repetition == 'none') {
      return reminderTime.isBefore(now);
    } else {
      // For recurring tasks, check if the next occurrence is due
      final nextReminderTime = getNextReminderTime();
      return nextReminderTime.isBefore(now);
    }
  }

  // Calculate the next occurrence for repeating tasks
  DateTime getNextReminderTime() {
    final now = DateTime.now();

    // If it's not a repeating task or the reminder is in the future, return the original time
    if (repetition == null || repetition == 'none' || reminderTime.isAfter(now)) {
      return reminderTime;
    }

    // Start from the original reminder time
    DateTime nextTime = reminderTime;

    // Find the next occurrence that is in the future
    while (nextTime.isBefore(now)) {
      switch (repetition) {
        case 'daily':
          nextTime = nextTime.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextTime = nextTime.add(const Duration(days: 7));
          break;
        case 'monthly':
        // Add approximately one month
          final int currentMonth = nextTime.month;
          final int currentYear = nextTime.year;

          int nextMonth = currentMonth + 1;
          int nextYear = currentYear;

          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear += 1;
          }

          int day = nextTime.day;
          final int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
          if (day > lastDayOfNextMonth) {
            day = lastDayOfNextMonth;
          }

          nextTime = DateTime(
            nextYear,
            nextMonth,
            day,
            nextTime.hour,
            nextTime.minute,
          );
          break;
        default:
          return reminderTime;
      }
    }

    return nextTime;
  }
}