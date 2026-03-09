import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

import '../services/voice_service.dart';
import '../viewmodels/taskviewmodels.dart';

class TaskDetailView extends StatefulWidget {
  const TaskDetailView({Key? key}) : super(key: key);

  @override
  _TaskDetailViewState createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final TaskViewModel _taskViewModel = Get.find<TaskViewModel>();
  final VoiceService _voiceService = Get.find<VoiceService>();
  
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  late String _taskId;
  late Task? _task;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedRepetition = 'none';
  bool _isVoiceReminder = false;
  bool _isEditing = false;
  
  bool _isListening = false;
  String _currentVoiceField = '';

  @override
  void initState() {
    super.initState();
    
    // Get task id from route arguments
    _taskId = Get.arguments as String;
    _loadTaskData();
    
    // Listen for voice recognition results
    _voiceService.textStream.listen((text) {
      if (_isListening && text.isNotEmpty && _isEditing) {
        setState(() {
          switch (_currentVoiceField) {
            case 'title':
              _titleController.text = text;
              break;
            case 'description':
              _descriptionController.text = text;
              break;
            default:
              break;
          }
          _isListening = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
  
  void _loadTaskData() {
    _task = _taskViewModel.getTaskById(_taskId);
    
    if (_task == null) {
      Get.snackbar(
        'Error',
        'Task not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      Get.back();
      return;
    }
    
    // Initialize controllers with task data
    _titleController.text = _task!.title;
    _descriptionController.text = _task!.description ?? '';
    _selectedRepetition = _task!.repetition ?? 'none';
    _isVoiceReminder = _task!.isVoiceReminder;
    
    // Get appropriate reminder time for recurring tasks
    final DateTime reminderToShow = _task!.repetition != 'none' && _task!.reminderTime.isBefore(DateTime.now())
        ? _task!.getNextReminderTime()
        : _task!.reminderTime;
    
    _selectedDate = reminderToShow;
    _selectedTime = TimeOfDay(hour: reminderToShow.hour, minute: reminderToShow.minute);
    
    _updateDateTimeControllers();
  }
  
  void _updateDateTimeControllers() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    _dateController.text = dateFormat.format(_selectedDate);
    _timeController.text = timeFormat.format(
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // About 10 years ahead
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        _updateDateTimeControllers();
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    if (!_isEditing) return;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        _updateDateTimeControllers();
      });
    }
  }
  
  void _startVoiceInput(String field) async {
    if (!_isEditing) return;
    
    setState(() {
      _currentVoiceField = field;
      _isListening = true;
    });
    
    await _voiceService.startListening();
  }
  
  void _stopVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    }
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      
      if (!_isEditing && _task != null) {
        // Reset form if canceling edit
        _loadTaskData();
      }
    });
  }
  
  void _saveTask() async {
    if (!_isEditing || _task == null) return;
    
    if (_formKey.currentState!.validate()) {
      try {
        final reminderDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        
        await _taskViewModel.updateTask(
          _taskId,
          _titleController.text,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          reminderDateTime,
          _selectedRepetition,
          _isVoiceReminder,
          _task!.customSoundPath,
        );
        
        setState(() {
          _isEditing = false;
          _loadTaskData(); // Refresh data
        });
        
        Get.snackbar(
          'Success',
          'Task updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to update task: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    }
  }
  
  void _deleteTask() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${_task?.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _task != null) {
      try {
        await _taskViewModel.deleteTask(_taskId);
        Get.back(); // Return to previous screen
        Get.snackbar(
          'Success',
          'Task deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete task: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
        actions: [
          // Toggle edit mode
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit Task',
            onPressed: _toggleEditMode,
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _saveTask,
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Task',
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Stop voice input if tapping outside
          _stopVoiceInput();
          // Hide keyboard
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task completion status
                SwitchListTile(
                  title: Text(
                    'Mark as ${_task!.isCompleted ? "Incomplete" : "Complete"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _task!.isCompleted ? Colors.grey[600] : Theme.of(context).primaryColor,
                    ),
                  ),
                  value: _task!.isCompleted,
                  onChanged: (value) async {
                    await _taskViewModel.toggleTaskCompletion(_taskId, value);
                    setState(() {
                      _loadTaskData(); // Refresh task data
                    });
                  },
                ),
                
                const Divider(),
                
                // Title input with voice option
                TextFormField(
                  controller: _titleController,
                  readOnly: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEditing
                        ? IconButton(
                            icon: Icon(_isListening && _currentVoiceField == 'title'
                                ? Icons.mic_off
                                : Icons.mic),
                            onPressed: () {
                              if (_isListening && _currentVoiceField == 'title') {
                                _stopVoiceInput();
                              } else {
                                _startVoiceInput('title');
                              }
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    decoration: _task!.isCompleted ? TextDecoration.lineThrough : null,
                    color: _task!.isCompleted ? Colors.grey[600] : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description input with voice option
                TextFormField(
                  controller: _descriptionController,
                  readOnly: !_isEditing,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEditing
                        ? IconButton(
                            icon: Icon(_isListening && _currentVoiceField == 'description'
                                ? Icons.mic_off
                                : Icons.mic),
                            onPressed: () {
                              if (_isListening && _currentVoiceField == 'description') {
                                _stopVoiceInput();
                              } else {
                                _startVoiceInput('description');
                              }
                            },
                          )
                        : null,
                  ),
                  style: TextStyle(
                    decoration: _task!.isCompleted ? TextDecoration.lineThrough : null,
                    color: _task!.isCompleted ? Colors.grey[600] : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date selection
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEditing
                        ? IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          )
                        : null,
                  ),
                  onTap: () => _isEditing ? _selectDate(context) : null,
                  style: TextStyle(
                    decoration: _task!.isCompleted ? TextDecoration.lineThrough : null,
                    color: _task!.isCompleted ? Colors.grey[600] : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Time selection
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEditing
                        ? IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context),
                          )
                        : null,
                  ),
                  onTap: () => _isEditing ? _selectTime(context) : null,
                  style: TextStyle(
                    decoration: _task!.isCompleted ? TextDecoration.lineThrough : null,
                    color: _task!.isCompleted ? Colors.grey[600] : null,
                  ),
                ),
                
                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  
                  // Repetition selection
                  Text(
                    'Repeat',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip('None', 'none'),
                      _buildChip('Daily', 'daily'),
                      _buildChip('Weekly', 'weekly'),
                      _buildChip('Monthly', 'monthly'),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  
                  // Display repetition
                  TextFormField(
                    initialValue: _selectedRepetition == 'none' 
                        ? 'No Repetition' 
                        : _capitalizeFirst(_selectedRepetition),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Repeats',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      decoration: _task!.isCompleted ? TextDecoration.lineThrough : null,
                      color: _task!.isCompleted ? Colors.grey[600] : null,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Voice reminder toggle
                SwitchListTile(
                  title: const Text('Voice Reminder'),
                  subtitle: const Text('Task will be announced aloud when due'),
                  value: _isVoiceReminder,
                  onChanged: _isEditing
                      ? (value) {
                          setState(() {
                            _isVoiceReminder = value;
                          });
                        }
                      : null,
                ),
                
                const SizedBox(height: 24),
                
                // Task information
                if (!_isEditing) ...[
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Created'),
                    subtitle: Text(
                      DateFormat('MMMM d, yyyy - h:mm a').format(_task!.createdAt),
                    ),
                  ),
                  
                  if (_task!.isDue && !_task!.isCompleted)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'This task is overdue',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                
                if (_isEditing) ...[
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedRepetition == value,
      onSelected: _isEditing
          ? (selected) {
              if (selected) {
                setState(() {
                  _selectedRepetition = value;
                });
              }
            }
          : null,
    );
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}