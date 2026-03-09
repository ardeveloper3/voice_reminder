import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(bool) onToggleCompletion;
  final VoidCallback onDelete;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onToggleCompletion,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Get the appropriate reminder time to display
    final DateTime reminderToShow = task.repetition != 'none' && task.reminderTime.isBefore(now)
        ? task.getNextReminderTime()
        : task.reminderTime;

    // Format time and date
    final String timeString = DateFormat.jm().format(reminderToShow);

    // For date, show "Today", "Tomorrow", or the actual date
    String dateString;
    final DateTime reminderDay = DateTime(
      reminderToShow.year,
      reminderToShow.month,
      reminderToShow.day,
    );

    if (reminderDay == today) {
      dateString = 'Today';
    } else if (reminderDay == today.add(const Duration(days: 1))) {
      dateString = 'Tomorrow';
    } else {
      dateString = DateFormat.MMMd().format(reminderToShow);
    }

    // Different styling based on completion status
    final textStyle = task.isCompleted
        ? TextStyle(
      decoration: TextDecoration.lineThrough,
      color: Colors.grey[600],
    )
        : const TextStyle();

    // Show overdue indicator if task is due
    final bool isOverdue = task.isDue && !task.isCompleted;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox for completion status
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      if (value != null) {
                        onToggleCompletion(value);
                      }
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),

                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with optional overdue indicator
                      Row(
                        children: [
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              task.title,
                              style: textStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Description if available
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            task.description!,
                            style: textStyle.copyWith(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Reminder time and repetition info
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: task.isCompleted ? Colors.grey[600] : Colors.grey[800],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dateString at $timeString',
                              style: textStyle.copyWith(
                                fontSize: 14,
                                color: task.isCompleted ? Colors.grey[600] : Colors.grey[800],
                              ),
                            ),
                            if (task.repetition != 'none')
                              Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.repeat,
                                    size: 16,
                                    color: task.isCompleted ? Colors.grey[600] : Colors.grey[800],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _capitalizeFirst(task.repetition ?? 'none'),
                                    style: textStyle.copyWith(
                                      fontSize: 14,
                                      color: task.isCompleted ? Colors.grey[600] : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            if (task.isVoiceReminder)
                              Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.record_voice_over,
                                    size: 16,
                                    color: task.isCompleted ? Colors.grey[600] : Colors.grey[800],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}