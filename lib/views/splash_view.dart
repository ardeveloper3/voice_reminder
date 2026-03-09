import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../services/backgrund_service.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart';
import '../services/notification_service.dart';
import '../utils/theam_service.dart';
import '../viewmodels/taskviewmodels.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  final RxString _statusMessage = 'Initializing...'.obs;
  final RxDouble _progress = 0.0.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;
  
  @override
  void initState() {
    super.initState();
    
    // Setup fade-in animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // Initialize app services
    _initServices();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _initServices() async {
    try {
      // Initialize storage service
      _statusMessage.value = 'Initializing storage...';
      _progress.value = 0.2;
      final storageService = await Get.put(StorageService()).init();
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
      
      // Initialize theme service
      _statusMessage.value = 'Loading theme...';
      _progress.value = 0.4;
      final themeService = await Get.put(ThemeService()).init();
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate loading
      
      // Initialize voice service
      _statusMessage.value = 'Setting up voice recognition...';
      _progress.value = 0.6;
      final voiceService = await Get.put(VoiceService()).init();
      await Future.delayed(const Duration(milliseconds: 400)); // Simulate loading
      
      // Initialize notification service
      _statusMessage.value = 'Preparing notifications...';
      _progress.value = 0.7;
      final notificationService = await Get.put(NotificationService()).init();
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate loading
      
      // Initialize background service
      _statusMessage.value = 'Configuring background services...';
      _progress.value = 0.8;
      final backgroundService = await Get.put(BackgroundService()).init();
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate loading
      
      // Initialize task view model
      _statusMessage.value = 'Loading tasks...';
      _progress.value = 0.9;
      final taskViewModel = await Get.put(TaskViewModel()).init();
      await Future.delayed(const Duration(milliseconds: 400)); // Simulate loading
      
      // All services initialized
      _statusMessage.value = 'Ready!';
      _progress.value = 1.0;
      
      // Add slight delay before proceeding to home screen
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate to home screen
      Get.offAllNamed('/home');
      
    } catch (e) {
      debugPrint('Error during initialization: $e');
      _hasError.value = true;
      _errorMessage.value = 'Failed to initialize: $e';
      _progress.value = 0.0;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.record_voice_over,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App name
              const Text(
                'Voice Task Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // App tagline
              const Text(
                'Organize your tasks with your voice',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 64),
              
              // Loading indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status message
                    Obx(() => Text(
                      _statusMessage.value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )),
                    
                    const SizedBox(height: 8),
                    
                    // Progress bar
                    Obx(() => _hasError.value
                        ? _buildErrorMessage()
                        : LinearProgressIndicator(
                            value: _progress.value,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 24,
        ),
        const SizedBox(height: 8),
        Obx(() => Text(
          _errorMessage.value,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        )),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Try again
            _hasError.value = false;
            _errorMessage.value = '';
            _progress.value = 0.0;
            _statusMessage.value = 'Initializing...';
            _initServices();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}