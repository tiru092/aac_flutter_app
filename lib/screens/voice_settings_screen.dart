import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../models/custom_voice.dart';
import '../utils/aac_helper.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final VoiceService _voiceService = VoiceService();
  List<CustomVoice> _availableVoices = [];
  CustomVoice? _currentVoice;
  bool _isRecording = false;
  bool _isLoading = true;
  String _statusMessage = '';
  final TextEditingController _voiceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeVoiceSettings();
  }

  @override
  void dispose() {
    _voiceNameController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Loading voices...';
      });

      // Initialize voice service if not already done
      await _voiceService.initialize();
      
      // Load available voices
      _availableVoices = _voiceService.availableVoices;
      _currentVoice = _voiceService.currentVoice;
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Voices loaded successfully';
      });
      
      // Clear status message after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading voices: ${e.toString()}';
      });
    }
  }

  Future<void> _playVoice(CustomVoice voice) async {
    try {
      setState(() {
        _statusMessage = 'Playing ${voice.name}...';
      });

      if (voice.isDefault) {
        // For default voices, use text-to-speech with a sample text
        await AACHelper.speak('Hello, this is ${voice.name}');
        _showMessage('Playing default voice: ${voice.name}');
        return;
      }
      
      // For custom voices, play the recorded file
      final success = await _voiceService.playCustomVoice(voice);
      if (success) {
        _showMessage('Playing voice: ${voice.name}');
      } else {
        _showMessage('Failed to play voice. File may be missing or corrupted.');
      }
    } catch (e) {
      _showMessage('Error playing voice: ${e.toString()}');
    }
  }

  Future<void> _selectVoice(CustomVoice voice) async {
    try {
      _voiceService.setCurrentVoice(voice);
      setState(() {
        _currentVoice = voice;
      });
      _showMessage('Selected voice: ${voice.name}');
      
      // Play a sample to confirm selection
      await _playVoice(voice);
    } catch (e) {
      _showMessage('Error selecting voice: ${e.toString()}');
    }
  }

  Future<void> _startRecording() async {
    if (_voiceNameController.text.trim().isEmpty) {
      _showMessage('Please enter a name for your voice recording');
      return;
    }

    try {
      setState(() {
        _isRecording = true;
        _statusMessage = 'Recording...';
      });

      final success = await _voiceService.startRecording(_voiceNameController.text.trim());
      if (!success) {
        setState(() {
          _isRecording = false;
          _statusMessage = 'Failed to start recording';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMessage = 'Error starting recording: ${e.toString()}';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _statusMessage = 'Stopping recording...';
      });

      final customVoice = await _voiceService.stopRecording();
      setState(() {
        _isRecording = false;
      });

      if (customVoice != null) {
        // Refresh the voices list
        _availableVoices = _voiceService.availableVoices;
        _showMessage('Voice recorded successfully: ${customVoice.name}');
        _voiceNameController.clear();
        
        // Auto-play the new recording
        await _playVoice(customVoice);
      } else {
        _showMessage('Failed to save recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showMessage('Error stopping recording: ${e.toString()}');
    }
  }

  Future<void> _deleteVoice(CustomVoice voice) async {
    if (voice.isDefault) {
      _showMessage('Cannot delete default voices');
      return;
    }

    try {
      final success = await _voiceService.deleteCustomVoice(voice);
      if (success) {
        setState(() {
          _availableVoices = _voiceService.availableVoices;
          _currentVoice = _voiceService.currentVoice;
        });
        _showMessage('Voice deleted: ${voice.name}');
      } else {
        _showMessage('Failed to delete voice');
      }
    } catch (e) {
      _showMessage('Error deleting voice: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
    
    // Clear message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  void _showDeleteConfirmation(CustomVoice voice) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Voice'),
        content: Text('Are you sure you want to delete "${voice.name}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVoice(voice);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Voice Settings'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  // Status message
                  if (_statusMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),

                  // Recording section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Record New Voice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _voiceNameController,
                          placeholder: 'Enter voice name',
                          enabled: !_isRecording,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton.filled(
                                onPressed: _isRecording ? _stopRecording : _startRecording,
                                child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Available voices section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Available Voices',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _availableVoices.length,
                              itemBuilder: (context, index) {
                                final voice = _availableVoices[index];
                                final isSelected = _currentVoice?.id == voice.id;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? CupertinoColors.activeBlue.withOpacity(0.1)
                                        : CupertinoColors.systemBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.systemGrey4,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: CupertinoListTile(
                                    title: Text(
                                      voice.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      voice.isDefault ? 'Default Voice' : 'Custom Voice',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                    leading: Icon(
                                      voice.isDefault 
                                          ? CupertinoIcons.speaker_2
                                          : CupertinoIcons.mic,
                                      color: isSelected 
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.systemGrey,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Play button
                                        CupertinoButton(
                                          padding: const EdgeInsets.all(8),
                                          onPressed: () => _playVoice(voice),
                                          child: const Icon(
                                            CupertinoIcons.play_circle,
                                            size: 24,
                                          ),
                                        ),
                                        // Select button
                                        if (!isSelected)
                                          CupertinoButton(
                                            padding: const EdgeInsets.all(8),
                                            onPressed: () => _selectVoice(voice),
                                            child: const Icon(
                                              CupertinoIcons.checkmark_circle,
                                              size: 24,
                                            ),
                                          ),
                                        // Delete button (only for custom voices)
                                        if (!voice.isDefault)
                                          CupertinoButton(
                                            padding: const EdgeInsets.all(8),
                                            onPressed: () => _showDeleteConfirmation(voice),
                                            child: const Icon(
                                              CupertinoIcons.delete,
                                              size: 24,
                                              color: CupertinoColors.destructiveRed,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () => _selectVoice(voice),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}