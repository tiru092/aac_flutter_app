import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/custom_voice.dart';
import '../utils/aac_helper.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  FlutterSoundRecorder? _audioRecorder;
  final AudioPlayer _defaultAudioPlayer = AudioPlayer();
  
  // Current recording file path
  String? _currentRecordingPath;
  
  // Available voices (including default and custom)
  final List<CustomVoice> _availableVoices = [
    CustomVoice(
      id: 'default_female',
      name: 'Default Female Voice',
      filePath: '',
      createdAt: DateTime.now(),
      isDefault: true,
      voiceType: VoiceType.female,
      gender: VoiceGender.female,
      description: 'Built-in female voice for text-to-speech',
    ),
    CustomVoice(
      id: 'default_male',
      name: 'Default Male Voice',
      filePath: '',
      createdAt: DateTime.now(),
      isDefault: true,
      voiceType: VoiceType.male,
      gender: VoiceGender.male,
      description: 'Built-in male voice for text-to-speech',
    ),
    CustomVoice(
      id: 'default_child',
      name: 'Child-Friendly Voice',
      filePath: '',
      createdAt: DateTime.now(),
      isDefault: true,
      voiceType: VoiceType.child,
      gender: VoiceGender.neutral,
      description: 'High-pitched child-friendly voice',
    ),
  ];
  
  // Current selected voice
  CustomVoice _currentVoice = CustomVoice(
    id: 'default_female',
    name: 'Default Female Voice',
    filePath: '',
    createdAt: DateTime.now(),
    isDefault: true,
    voiceType: VoiceType.female,
    gender: VoiceGender.female,
    description: 'Built-in female voice for text-to-speech',
  );
  
  // Get available voices
  List<CustomVoice> get availableVoices => List.unmodifiable(_availableVoices);
  
  // Get current voice
  CustomVoice get currentVoice => _currentVoice;
  
  // Set current voice
  void setCurrentVoice(CustomVoice voice) {
    _currentVoice = voice;
    // Save to settings
    AACHelper.setSetting('current_voice_id', voice.id);
  }
  
  // Initialize the voice service
  Future<void> initialize() async {
    try {
      // Initialize audio recorder only
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
      
      debugPrint('VoiceService initialized successfully');
      
      // Load saved voice preference
      final savedVoiceId = AACHelper.getSetting<String>('current_voice_id');
      if (savedVoiceId != null) {
        final savedVoice = _availableVoices.firstWhere(
          (voice) => voice.id == savedVoiceId,
          orElse: () => _availableVoices.first,
        );
        _currentVoice = savedVoice;
      }
      
      // Load custom voices from storage
      await _loadCustomVoices();
    } catch (e) {
      debugPrint('Error initializing VoiceService: $e');
    }
  }
  
  // Load custom voices from storage
  Future<void> _loadCustomVoices() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final voicesDir = Directory('${dir.path}/voices');
      
      if (await voicesDir.exists()) {
        final files = voicesDir.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.m4a')) {
            final fileName = file.path.split('/').last;
            final voiceName = fileName.replaceAll('.m4a', '');
            
            // Determine voice type and gender based on name
            final voiceTypeInfo = _determineVoiceType(voiceName);
            
            final customVoice = CustomVoice(
              id: fileName,
              name: voiceName,
              filePath: file.path,
              createdAt: DateTime.now(),
              isDefault: false,
              voiceType: voiceTypeInfo['type'] as VoiceType,
              gender: voiceTypeInfo['gender'] as VoiceGender,
              description: 'Custom recorded voice',
            );
            
            // Add to available voices if not already present
            if (!_availableVoices.any((voice) => voice.id == customVoice.id)) {
              _availableVoices.add(customVoice);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading custom voices: $e');
    }
  }
  
  // Check if recording is currently active
  bool get isRecording {
    if (_audioRecorder == null) return false;
    return _audioRecorder!.isRecording;
  }
  
  // Start recording a custom voice
  Future<bool> startRecording(String voiceName) async {
    try {
      if (!await _checkPermissions()) {
        debugPrint('Recording permissions not granted');
        return false;
      }

      if (_audioRecorder == null) {
        debugPrint('Audio recorder not initialized');
        return false;
      }
      
      if (_audioRecorder!.isRecording) {
        await _audioRecorder!.stopRecorder();
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final voicesDir = Directory('${dir.path}/voices');
      if (!await voicesDir.exists()) {
        await voicesDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${voicesDir.path}/${voiceName}_$timestamp.m4a';
      
      await _audioRecorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
      );
      
      debugPrint('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }
  
  // Check recording permissions
  Future<bool> _checkPermissions() async {
    try {
      // Check microphone permission
      var microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus != PermissionStatus.granted) {
        microphoneStatus = await Permission.microphone.request();
        if (microphoneStatus != PermissionStatus.granted) {
          debugPrint('Microphone permission denied');
          return false;
        }
      }
      
      // For Android 13+ (API 33+), we need different storage permissions
      if (Platform.isAndroid) {
        // Try to use the app's internal storage instead of external storage
        // This doesn't require storage permissions
        debugPrint('Using internal app storage for recordings');
        return true;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }
  
  // Stop recording and save the custom voice with enhanced error handling
  Future<CustomVoice?> stopRecording() async {
    try {
      if (_audioRecorder == null || !isRecording) {
        debugPrint('No active recording to stop');
        return null;
      }
      
      // Stop recording but keep the session open
      await _audioRecorder!.stopRecorder();
      
      // Create custom voice object
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (!await file.exists()) {
          debugPrint('Recording file not created: $_currentRecordingPath');
          return null;
        }
        
        final voiceName = _currentRecordingPath!
            .split('/')
            .last
            .replaceAll('.m4a', '');
        
        // Determine voice type and gender based on name
        final voiceTypeInfo = _determineVoiceType(voiceName);
            
        final customVoice = CustomVoice(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          name: voiceName,
          filePath: _currentRecordingPath!,
          createdAt: DateTime.now(),
          isDefault: false,
          voiceType: voiceTypeInfo['type'] as VoiceType,
          gender: voiceTypeInfo['gender'] as VoiceGender,
          description: 'Custom recorded voice',
        );
        
        // Add to available voices
        _availableVoices.add(customVoice);
        
        // Save to persistent storage
        await _saveCustomVoice(customVoice);
        
        debugPrint('Recording saved: ${customVoice.name}');
        
        // Clear the current recording path for next recording
        _currentRecordingPath = null;
        
        return customVoice;
      }
      
      debugPrint('No recording path set');
      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    } finally {
      // Clear the recording path but keep the session open
      _currentRecordingPath = null;
    }
  }
  
  // Save custom voice to persistent storage
  Future<void> _saveCustomVoice(CustomVoice voice) async {
    try {
      // In a full implementation, you might save voice metadata to Hive
      // For now, we're just managing the files directly
      debugPrint('Saved custom voice: ${voice.name}');
    } catch (e) {
      debugPrint('Error saving custom voice: $e');
    }
  }
  
  // Delete a custom voice
  Future<bool> deleteCustomVoice(CustomVoice voice) async {
    try {
      if (voice.isDefault) {
        debugPrint('Cannot delete default voice');
        return false;
      }
      
      // Delete the audio file
      if (voice.filePath.isNotEmpty) {
        final file = File(voice.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remove from available voices
      _availableVoices.removeWhere((v) => v.id == voice.id);
      
      // If this was the current voice, switch to default
      if (_currentVoice.id == voice.id) {
        _currentVoice = _availableVoices.firstWhere(
          (v) => v.isDefault,
          orElse: () => _availableVoices.first,
        );
        // Save preference
        AACHelper.setSetting('current_voice_id', _currentVoice.id);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting custom voice: $e');
      return false;
    }
  }
  
  // Play a custom voice recording
  Future<bool> playCustomVoice(CustomVoice voice) async {
    try {
      if (voice.isDefault) {
        // For default voices, we use TTS through AACHelper
        debugPrint('Playing default voice through TTS');
        return true;
      }
      
      // For custom voices, play the recorded audio file
      if (voice.filePath.isNotEmpty) {
        final file = File(voice.filePath);
        if (await file.exists()) {
          // Use the dedicated audio player (not the recorder's player)
          await _defaultAudioPlayer.play(DeviceFileSource(voice.filePath));
          debugPrint('Playing custom voice: ${voice.name}');
          return true;
        }
      }
      
      debugPrint('Voice file not found: ${voice.filePath}');
      return false;
    } catch (e) {
      debugPrint('Error playing custom voice: $e');
      return false;
    }
  }
  
  // Stop current playback
  Future<void> stopPlayback() async {
    try {
      await _defaultAudioPlayer.stop();
      debugPrint('Playback stopped');
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }
  
  // Speak text using the current voice - FIXED to avoid recursion
  Future<void> speakWithCurrentVoice(String text) async {
    if (_currentVoice.isDefault) {
      // For default voices, use Flutter TTS directly to avoid recursion
      await _speakWithFlutterTts(text);
    } else {
      // For custom voices, play the recorded audio if it matches the text
      // In a full implementation, you might have recorded phrases
      // For now, we'll fall back to TTS
      await _speakWithFlutterTts(text);
    }
  }
  
  // Internal method to speak using Flutter TTS directly
  Future<void> _speakWithFlutterTts(String text) async {
    try {
      // Use AACHelper's FlutterTts instance directly
      final flutterTts = AACHelper.getFlutterTtsInstance();
      if (flutterTts != null) {
        // Configure TTS based on current voice type
        await _configureTtsForVoiceType(flutterTts);
        await flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('Error speaking with Flutter TTS: $e');
    }
  }
  
  /// Configure TTS settings based on voice type
  Future<void> _configureTtsForVoiceType(dynamic flutterTts) async {
    try {
      // Use user's custom settings if available, otherwise use voice type defaults
      double userSpeechRate = AACHelper.speechRate;
      double userSpeechPitch = AACHelper.speechPitch;
      double userSpeechVolume = AACHelper.speechVolume;
      
      // Apply user's custom settings
      await flutterTts.setSpeechRate(userSpeechRate);
      await flutterTts.setPitch(userSpeechPitch);
      await flutterTts.setVolume(userSpeechVolume);
      
      debugPrint('Applied user speech settings - Rate: $userSpeechRate, Pitch: $userSpeechPitch, Volume: $userSpeechVolume');
    } catch (e) {
      debugPrint('Error configuring TTS for voice type: $e');
    }
  }
  
  /// Determine voice type and gender based on voice name
  Map<String, dynamic> _determineVoiceType(String voiceName) {
    final lowerName = voiceName.toLowerCase();
    
    // Check for male indicators
    if (lowerName.contains('male') || 
        lowerName.contains('man') || 
        lowerName.contains('boy') ||
        lowerName.contains('father') ||
        lowerName.contains('dad') ||
        lowerName.contains('mr')) {
      return {
        'type': VoiceType.male,
        'gender': VoiceGender.male,
      };
    }
    
    // Check for child indicators
    if (lowerName.contains('child') || 
        lowerName.contains('kid') || 
        lowerName.contains('young') ||
        lowerName.contains('toddler') ||
        lowerName.contains('baby')) {
      return {
        'type': VoiceType.child,
        'gender': VoiceGender.neutral,
      };
    }
    
    // Check for female indicators (including default)
    if (lowerName.contains('female') || 
        lowerName.contains('woman') || 
        lowerName.contains('girl') ||
        lowerName.contains('mother') ||
        lowerName.contains('mom') ||
        lowerName.contains('mrs') ||
        lowerName.contains('ms')) {
      return {
        'type': VoiceType.female,
        'gender': VoiceGender.female,
      };
    }
    
    // Default to female if no specific indicators found
    return {
      'type': VoiceType.female,
      'gender': VoiceGender.female,
    };
  }
  
  /// Get voices by type
  List<CustomVoice> getVoicesByType(VoiceType type) {
    return _availableVoices.where((voice) => voice.voiceType == type).toList();
  }
  
  /// Get voices by gender
  List<CustomVoice> getVoicesByGender(VoiceGender gender) {
    return _availableVoices.where((voice) => voice.gender == gender).toList();
  }
  
  /// Get default voices
  List<CustomVoice> getDefaultVoices() {
    return _availableVoices.where((voice) => voice.isDefault).toList();
  }
  
  /// Get custom voices
  List<CustomVoice> getCustomVoices() {
    return _availableVoices.where((voice) => !voice.isDefault).toList();
  }
  
  /// Set voice by type (automatically selects appropriate voice)
  void setVoiceByType(VoiceType type) {
    final voicesOfType = getVoicesByType(type);
    if (voicesOfType.isNotEmpty) {
      // Prefer default voices, then custom
      final defaultVoice = voicesOfType.where((v) => v.isDefault).firstOrNull;
      _currentVoice = defaultVoice ?? voicesOfType.first;
    }
  }
  
  /// Set voice by gender (automatically selects appropriate voice)
  void setVoiceByGender(VoiceGender gender) {
    final voicesOfGender = getVoicesByGender(gender);
    if (voicesOfGender.isNotEmpty) {
      // Prefer default voices, then custom
      final defaultVoice = voicesOfGender.where((v) => v.isDefault).firstOrNull;
      _currentVoice = defaultVoice ?? voicesOfGender.first;
    }
  }
  
  // Dispose resources - only called when the service is being destroyed
  Future<void> dispose() async {
    try {
      // Stop any ongoing recording
      if (_audioRecorder?.isRecording == true) {
        await _audioRecorder!.stopRecorder();
      }
      
      // Close recorder session
      await _audioRecorder?.closeRecorder();
      
      // Stop and dispose audio players
      await _defaultAudioPlayer.stop();
      await _defaultAudioPlayer.dispose();
      
      debugPrint('VoiceService disposed successfully');
    } catch (e) {
      debugPrint('Error disposing voice service: $e');
    }
  }
}