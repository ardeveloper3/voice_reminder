import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';

import '../viewmodels/taskviewmodels.dart';
import '../widgets/task_list_item.dart';
import '../services/voice_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  final TaskViewModel _taskViewModel = Get.find<TaskViewModel>();
  final VoiceService _voiceService = Get.find<VoiceService>();
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen for voice search results
    _voiceService.textStream.listen((recognizedText) {
      if (recognizedText.isNotEmpty) {
        _searchController.text = recognizedText;
        _taskViewModel.searchTasks(recognizedText);
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          // Show search bar or title
          return _taskViewModel.searchQuery.isEmpty
              ? const Text('Voice Task Assistant')
              : _buildSearchField();
        }),
        actions: [
          // Voice search button
          IconButton(
            onPressed: () async {
              await _taskViewModel.startVoiceSearch();
            },
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Search',
          ),
          // Text search toggle button
          IconButton(
            onPressed: () {
              if (_taskViewModel.searchQuery.isEmpty) {
                _taskViewModel.searchTasks(' '); // Start with empty search
                _searchFocusNode.requestFocus();
              } else {
                _taskViewModel.searchTasks(''); // Clear search
              }
            },
            icon: Obx(() => Icon(
                _taskViewModel.searchQuery.isEmpty
                    ? Icons.search
                    : Icons.clear)),
            tooltip: 'Search Tasks',
          ),
          // Settings button
          IconButton(
            onPressed: () => Get.toNamed('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
        bottom: _taskViewModel.searchQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                ],
              )
            : null,
      ),
      body: Obx(() {
        if (_taskViewModel.searchQuery.isNotEmpty) {
          return _buildSearchResults();
        } else {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(_taskViewModel.todayTasks),
              _buildTaskList(_taskViewModel.upcomingTasks),
              _buildTaskList(_taskViewModel.completedTasks),
            ],
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/task/create'),
        child: const Icon(Icons.add),
        tooltip: 'Create Task',
      ),
    );
  }
  
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: const InputDecoration(
        hintText: 'Search tasks...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        _taskViewModel.searchTasks(value);
      },
    );
  }
  
  Widget _buildSearchResults() {
    final results = _taskViewModel.searchResults;
    
    if (results.isEmpty) {
      return const Center(
        child: Text('No matching tasks found'),
      );
    }
    
    return _buildTaskList(results);
  }
  
  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/task/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create New Task'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(
          task: task,
          onTap: () => Get.toNamed('/task/detail', arguments: task.id),
          onToggleCompletion: (isCompleted) {
            _taskViewModel.toggleTaskCompletion(task.id, isCompleted);
          },
          onDelete: () async {
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Delete Task'),
                content: Text('Are you sure you want to delete "${task.title}"?'),
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
            
            if (confirmed == true) {
              await _taskViewModel.deleteTask(task.id);
            }
          },
        );
      },
    );
  }
}