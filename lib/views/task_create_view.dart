import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/voice_service.dart';
import '../viewmodels/taskviewmodels.dart';

class TaskCreateView extends StatefulWidget {
  const TaskCreateView({Key? key}) : super(key: key);

  @override
  _TaskCreateViewState createState() => _TaskCreateViewState();
}

class _TaskCreateViewState extends State<TaskCreateView> {
  final TaskViewModel _taskViewModel = Get.find<TaskViewModel>();
  final VoiceService _voiceService = Get.find<VoiceService>();
  
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedRepetition = 'none';
  bool _isVoiceReminder = false;
  
  bool _isListening = false;
  String _currentVoiceField = '';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize date and time fields
    _updateDateTimeControllers();
    
    // Listen for voice recognition results
    _voiceService.textStream.listen((text) {
      if (_isListening && text.isNotEmpty) {
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
  
  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        final reminderDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        
        await _taskViewModel.addTask(
          _titleController.text,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          reminderDateTime,
          _selectedRepetition,
          _isVoiceReminder,
          null, // No custom sound path for now
        );
        
        Get.back();
        Get.snackbar(
          'Success',
          'Task created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to create task: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Task',
            onPressed: _saveTask,
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
                // Title input with voice option
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'What do you need to do?',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
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
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Description input with voice option
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add details about the task',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
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
                    ),
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
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  onTap: () => _selectDate(context),
                ),
                
                const SizedBox(height: 16),
                
                // Time selection
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => _selectTime(context),
                    ),
                  ),
                  onTap: () => _selectTime(context),
                ),
                
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
                
                const SizedBox(height: 24),
                
                // Voice reminder toggle
                SwitchListTile(
                  title: const Text('Voice Reminder'),
                  subtitle: const Text('Task will be announced aloud when due'),
                  value: _isVoiceReminder,
                  onChanged: (value) {
                    setState(() {
                      _isVoiceReminder = value;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    child: const Text(
                      'CREATE TASK',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
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
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRepetition = value;
          });
        }
      },
    );
  }
}
