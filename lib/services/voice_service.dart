import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/symbol.dart'; // For CustomVoice model
import '../utils/aac_helper.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
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
    ),
    CustomVoice(
      id: 'default_male',
      name: 'Default Male Voice',
      filePath: '',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
  ];
  
  // Current selected voice
  CustomVoice _currentVoice = CustomVoice(
    id: 'default_female',
    name: 'Default Female Voice',
    filePath: '',
    createdAt: DateTime.now(),
    isDefault: true,
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
    // Initialize audio recorder and player
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    
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
            
            final customVoice = CustomVoice(
              id: fileName,
              name: voiceName,
              filePath: file.path,
              createdAt: DateTime.now(),
              isDefault: false,
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
      // Ensure recorder is initialized
      _audioRecorder ??= FlutterSoundRecorder();
      
      // Close any existing session
      try {
        await _audioRecorder!.closeRecorder();
      } catch (e) {
        debugPrint('Error closing existing recorder: $e');
      }
      
      // Open audio session
      await _audioRecorder!.openRecorder();
      
      // Get directory for voice recordings
      final dir = await getApplicationDocumentsDirectory();
      final voicesDir = Directory('${dir.path}/voices');
      
      // Create directory if it doesn't exist
      if (!await voicesDir.exists()) {
        await voicesDir.create(recursive: true);
      }
      
      // Set recording path
      _currentRecordingPath = '${voicesDir.path}/$voiceName.m4a';
      
      // Start recording
      await _audioRecorder!.startRecorder(toFile: _currentRecordingPath);
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }
  
  // Stop recording and save the custom voice
  Future<CustomVoice?> stopRecording() async {
    try {
      if (_audioRecorder == null || !isRecording) {
        return null;
      }
      
      // Stop recording
      await _audioRecorder!.stopRecorder();
      
      // Create custom voice object
      if (_currentRecordingPath != null) {
        final voiceName = _currentRecordingPath!
            .split('/')
            .last
            .replaceAll('.m4a', '');
            
        final customVoice = CustomVoice(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          name: voiceName,
          filePath: _currentRecordingPath!,
          createdAt: DateTime.now(),
          isDefault: false,
        );
        
        // Add to available voices
        _availableVoices.add(customVoice);
        
        // Save to persistent storage
        await _saveCustomVoice(customVoice);
        
        return customVoice;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    } finally {
      // Always close the recorder
      try {
        await _audioRecorder?.closeRecorder();
      } catch (e) {
        debugPrint('Error closing recorder: $e');
      }
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
        // We don't directly call AACHelper.speak here to avoid recursion
        // Instead, we return true and let the caller handle TTS
        debugPrint('Playing default voice through TTS');
        return true;
      }
      
      // For custom voices, play the recorded audio file
      if (voice.filePath.isNotEmpty) {
        final file = File(voice.filePath);
        if (await file.exists()) {
          // Ensure player is initialized
          _audioPlayer ??= FlutterSoundPlayer();
          
          // Close any existing session
          try {
            await _audioPlayer!.closePlayer();
          } catch (e) {
            debugPrint('Error closing existing player: $e');
          }
          
          // Open player and play
          await _audioPlayer!.openPlayer();
          await _audioPlayer!.startPlayer(fromURI: voice.filePath);
          return true;
        }
      }
      
      debugPrint('Voice file not found');
      return false;
    } catch (e) {
      debugPrint('Error playing custom voice: $e');
      return false;
    } finally {
      // Close player after a delay to allow playback to complete
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          await _audioPlayer?.closePlayer();
        } catch (e) {
          debugPrint('Error closing player: $e');
        }
      });
    }
  }
  
  // Stop current playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer?.stopPlayer();
      await _audioPlayer?.closePlayer();
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
        await flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('Error speaking with Flutter TTS: $e');
    }
  }
  
  // Dispose resources
  Future<void> dispose() async {
    try {
      await _audioRecorder?.closeRecorder();
      await _audioPlayer?.closePlayer();
      await _defaultAudioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing voice service: $e');
    }
  }
}