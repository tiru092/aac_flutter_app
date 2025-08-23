import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../models/symbol.dart';
import '../utils/aac_helper.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final VoiceService _voiceService = VoiceService(); // Singleton instance
  late List<CustomVoice> _availableVoices;
  CustomVoice? _selectedVoice;
  bool _isRecording = false;
  String _recordingStatus = '';
  String _newVoiceName = '';
  final TextEditingController _voiceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  @override
  void dispose() {
    _voiceNameController.dispose();
    // Stop any ongoing recording or playback
    if (_isRecording) {
      _stopRecording();
    }
    super.dispose();
  }

  Future<void> _loadVoices() async {
    setState(() {
      _availableVoices = _voiceService.availableVoices;
      _selectedVoice = _voiceService.currentVoice;
    });
  }

  Future<void> _startRecording() async {
    if (_newVoiceName.isEmpty) {
      _showMessage('Please enter a name for your voice');
      return;
    }

    try {
      final success = await _voiceService.startRecording(_newVoiceName);
      if (success) {
        setState(() {
          _isRecording = true;
          _recordingStatus = 'Recording... Speak now';
        });

        // Auto-stop after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isRecording) {
            _stopRecording();
          }
        });
      } else {
        _showMessage('Failed to start recording');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final customVoice = await _voiceService.stopRecording();
      if (customVoice != null) {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Recording saved!';
          _newVoiceName = '';
          _voiceNameController.clear();
        });

        _showMessage('Voice recorded successfully!');
        _loadVoices(); // Refresh the list
      } else {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Recording failed';
        });
        _showMessage('Failed to save recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Recording error';
      });
      _showMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _selectVoice(CustomVoice voice) async {
    setState(() {
      _selectedVoice = voice;
    });
    _voiceService.setCurrentVoice(voice);
    _showMessage('Voice selected: ${voice.name}');
  }

  Future<void> _deleteVoice(CustomVoice voice) async {
    if (voice.isDefault) {
      _showMessage('Cannot delete default voices');
      return;
    }

    final success = await _voiceService.deleteCustomVoice(voice);
    if (success) {
      _showMessage('Voice deleted successfully');
      _loadVoices(); // Refresh the list
      
      // If we deleted the current voice, select the first available
      if (_selectedVoice?.id == voice.id) {
        setState(() {
          _selectedVoice = _availableVoices.isNotEmpty ? _availableVoices.first : null;
        });
        if (_selectedVoice != null) {
          _voiceService.setCurrentVoice(_selectedVoice!);
        }
      }
    } else {
      _showMessage('Failed to delete voice');
    }
  }

  Future<void> _playVoice(CustomVoice voice) async {
    final success = await _voiceService.playCustomVoice(voice);
    if (success) {
      _showMessage('Playing voice: ${voice.name}');
    } else {
      _showMessage('Failed to play voice');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF4ECDC4),
        middle: Text(
          '🎙️ Voice Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Current voice indicator
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Current Voice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedVoice?.name ?? 'Default Female Voice',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),

            // Voice recording section
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record Your Own Voice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _voiceNameController,
                    placeholder: 'Enter voice name (e.g., Mom, Dad)',
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _newVoiceName = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_isRecording) ...[
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(20),
                          onPressed: _startRecording,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.mic, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Record',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(20),
                          onPressed: _stopRecording,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.stop_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Stop',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 12),
                    Text(
                      _recordingStatus,
                      style: const TextStyle(
                        color: Color(0xFFE53E3E),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Available voices list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Available Voices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _availableVoices.length,
                        itemBuilder: (context, index) {
                          final voice = _availableVoices[index];
                          final isSelected = _selectedVoice?.id == voice.id;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF4ECDC4).withOpacity(0.2) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF4ECDC4) 
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              leading: Icon(
                                voice.isDefault 
                                    ? CupertinoIcons.person_circle 
                                    : CupertinoIcons.mic_circle,
                                color: voice.isDefault 
                                    ? const Color(0xFF6C63FF) 
                                    : const Color(0xFF4ECDC4),
                                size: 32,
                              ),
                              title: Text(
                                voice.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              subtitle: Text(
                                voice.isDefault 
                                    ? 'Default voice' 
                                    : 'Custom recorded voice',
                                style: const TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minSize: 30,
                                    onPressed: () => _playVoice(voice),
                                    child: const Icon(
                                      CupertinoIcons.play_circle,
                                      color: Color(0xFF4ECDC4),
                                      size: 24,
                                    ),
                                  ),
                                  if (!voice.isDefault)
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minSize: 30,
                                      onPressed: () => _deleteVoice(voice),
                                      child: const Icon(
                                        CupertinoIcons.delete,
                                        color: Color(0xFFE53E3E),
                                        size: 24,
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