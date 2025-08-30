import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../models/custom_voice.dart';

class RecordingTestScreen extends StatefulWidget {
  const RecordingTestScreen({super.key});

  @override
  State<RecordingTestScreen> createState() => _RecordingTestScreenState();
}

class _RecordingTestScreenState extends State<RecordingTestScreen> {
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _voiceNameController = TextEditingController();
  
  bool _isRecording = false;
  bool _isInitialized = false;
  String _statusMessage = 'Tap Initialize to start';
  List<String> _debugMessages = [];

  @override
  void initState() {
    super.initState();
    _voiceNameController.text = 'test_voice_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _voiceNameController.dispose();
    super.dispose();
  }

  void _addDebugMessage(String message) {
    setState(() {
      _debugMessages.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_debugMessages.length > 20) {
        _debugMessages.removeLast();
      }
    });
    print('DEBUG: $message'); // Also print to console
  }

  Future<void> _initializeService() async {
    _addDebugMessage('Initializing VoiceService...');
    setState(() {
      _statusMessage = 'Initializing...';
    });

    try {
      await _voiceService.initialize();
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Service initialized successfully';
      });
      _addDebugMessage('VoiceService initialized successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
      _addDebugMessage('Initialization failed: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) {
      _addDebugMessage('Service not initialized');
      return;
    }

    if (_voiceNameController.text.trim().isEmpty) {
      _addDebugMessage('Voice name is empty');
      return;
    }

    _addDebugMessage('Starting recording: ${_voiceNameController.text}');
    setState(() {
      _isRecording = true;
      _statusMessage = 'Starting recording...';
    });

    try {
      final success = await _voiceService.startRecording(_voiceNameController.text.trim());
      
      if (success) {
        setState(() {
          _statusMessage = 'Recording... Tap Stop to finish';
        });
        _addDebugMessage('Recording started successfully');
      } else {
        setState(() {
          _isRecording = false;
          _statusMessage = 'Failed to start recording';
        });
        _addDebugMessage('Failed to start recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error starting recording: $e';
      });
      _addDebugMessage('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _addDebugMessage('Stopping recording...');
    setState(() {
      _statusMessage = 'Stopping recording...';
    });

    try {
      final customVoice = await _voiceService.stopRecording();
      
      setState(() {
        _isRecording = false;
      });

      if (customVoice != null) {
        setState(() {
          _statusMessage = 'Recording saved: ${customVoice.name}';
        });
        _addDebugMessage('Recording saved successfully: ${customVoice.name}');
        
        // Generate new name for next recording
        _voiceNameController.text = 'test_voice_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        setState(() {
          _statusMessage = 'Failed to save recording';
        });
        _addDebugMessage('Failed to save recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error stopping recording: $e';
      });
      _addDebugMessage('Error stopping recording: $e');
    }
  }

  Future<void> _testPlayback() async {
    _addDebugMessage('Testing playback...');
    
    final voices = _voiceService.availableVoices;
    final customVoices = voices.where((v) => !v.isDefault).toList();
    
    if (customVoices.isEmpty) {
      _addDebugMessage('No custom voices to test');
      return;
    }
    
    final voice = customVoices.last;
    _addDebugMessage('Playing voice: ${voice.name}');
    
    try {
      final success = await _voiceService.playCustomVoice(voice);
      if (success) {
        _addDebugMessage('Playback started successfully');
      } else {
        _addDebugMessage('Playback failed');
      }
    } catch (e) {
      _addDebugMessage('Playback error: $e');
    }
  }

  void _clearDebugMessages() {
    setState(() {
      _debugMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Recording Test'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Controls
              if (!_isInitialized) ...[
                CupertinoButton.filled(
                  onPressed: _initializeService,
                  child: const Text('Initialize Service'),
                ),
              ] else ...[
                // Voice name input
                CupertinoTextField(
                  controller: _voiceNameController,
                  placeholder: 'Voice name',
                  enabled: !_isRecording,
                ),
                
                const SizedBox(height: 16),
                
                // Recording controls
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CupertinoButton(
                        onPressed: _testPlayback,
                        child: const Text('Test Playback'),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Debug section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debug Messages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _clearDebugMessages,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Debug messages
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _debugMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'No debug messages yet',
                            style: TextStyle(color: CupertinoColors.systemGrey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _debugMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _debugMessages[index],
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}