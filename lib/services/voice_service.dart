import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends GetxService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // Observable states
  final RxBool _isListening = false.obs;
  final RxBool _isSpeaking = false.obs;
  final RxString _recognizedText = ''.obs;
  final RxDouble _speechConfidence = 0.0.obs;
  final RxString _lastError = ''.obs;

  // Getters for the observables
  bool get isListening => _isListening.value;
  bool get isSpeaking => _isSpeaking.value;
  String get recognizedText => _recognizedText.value;
  double get speechConfidence => _speechConfidence.value;
  String get lastError => _lastError.value;

  // Stream for continuous recognition
  final _textStreamController = RxString('');
  RxString get textStream => _textStreamController;

  Future<VoiceService> init() async {
    try {
      // Initialize speech recognition
      await _initSpeech();

      // Initialize text to speech
      await _initTts();

      debugPrint('Voice service initialized successfully');
      return this;
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
      _lastError.value = e.toString();
      return this;
    }
  }

  Future<void> _initSpeech() async {
    try {
      // Check permission
      await _checkPermission();

      // Initialize speech recognition
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');

          if (status == 'notListening') {
            _isListening.value = false;
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _lastError.value = error.errorMsg;
          _isListening.value = false;
        },
      );

      debugPrint('Speech recognition available: $available');
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      _lastError.value = e.toString();
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking.value = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _lastError.value = msg;
        _isSpeaking.value = false;
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _lastError.value = e.toString();
    }
  }

  Future<bool> _checkPermission() async {
    // Check and request microphone permission
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      // Request permission
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  // Start listening for speech
  Future<bool> startListening() async {
    if (_isListening.value) {
      await stopListening();
    }

    // Clear previous results
    _recognizedText.value = '';
    _textStreamController.value = '';

    try {
      // Check permission first
      final permissionGranted = await _checkPermission();

      if (!permissionGranted) {
        _lastError.value = 'Microphone permission denied';
        return false;
      }

      final available = await _speech.initialize();

      if (!available) {
        _lastError.value = 'Speech recognition not available';
        return false;
      }

      _isListening.value = await _speech.listen(
        onResult: (result) {
          _speechConfidence.value = result.confidence;
          _recognizedText.value = result.recognizedWords;
          _textStreamController.value = result.recognizedWords;

          debugPrint('Recognized: ${result.recognizedWords} (${result.confidence})');
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      return _isListening.value;
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _lastError.value = e.toString();
      _isListening.value = false;
      return false;
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening.value) {
      await _speech.stop();
      _isListening.value = false;
    }
  }

  // Speak text
  Future<bool> speak(String text) async {
    if (text.isEmpty) return false;

    if (_isSpeaking.value) {
      await stopSpeaking();
    }

    try {
      final result = await _flutterTts.speak(text);
      return result == 1;
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _lastError.value = e.toString();
      return false;
    }
  }

  // Stop speaking
  Future<bool> stopSpeaking() async {
    try {
      final result = await _flutterTts.stop();
      _isSpeaking.value = false;
      return result == 1;
    } catch (e) {
      debugPrint('Error stopping speech: $e');
      _lastError.value = e.toString();
      return false;
    }
  }

  // Get current recognized text
  String getCurrentText() {
    return _recognizedText.value;
  }

  // Close the service
  Future<void> close() async {
    await stopListening();
    await stopSpeaking();
  }
}