import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/aac_helper.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  bool _highContrast = false;
  bool _largeText = false;
  bool _voiceFeedback = false;
  bool _hapticFeedback = false;
  bool _autoSpeak = false;
  double _speechRate = 0.5;
  double _speechPitch = 1.2;
  double _speechVolume = 1.0;
  bool _soundEffects = false;
  double _soundVolume = 0.8;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _highContrast = AACHelper.isHighContrastEnabled;
      _largeText = AACHelper.isLargeTextEnabled;
      _voiceFeedback = AACHelper.isVoiceFeedbackEnabled;
      _hapticFeedback = AACHelper.isHapticFeedbackEnabled;
      _autoSpeak = AACHelper.isAutoSpeakEnabled;
      _speechRate = AACHelper.speechRate;
      _speechPitch = AACHelper.speechPitch;
      _speechVolume = AACHelper.speechVolume;
      _soundEffects = AACHelper.isSoundEffectsEnabled;
      _soundVolume = AACHelper.soundVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AACHelper.isHighContrastEnabled 
            ? Colors.black 
            : AACHelper.childFriendlyColors[0],
        middle: Text(
          '🔧 Accessibility Settings',
          style: TextStyle(
            fontSize: 18 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 24 * AACHelper.getTextSizeMultiplier(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AACHelper.isHighContrastEnabled
                ? [Colors.white, Colors.grey.shade200]
                : [
                    AACHelper.childFriendlyColors[0].withOpacity(0.1),
                    AACHelper.childFriendlyColors[2].withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('👁️ Visual Accessibility'),
                _buildSettingCard([
                  _buildToggleSetting(
                    title: 'High Contrast Mode',
                    subtitle: 'Increases contrast for better visibility',
                    icon: CupertinoIcons.eye,
                    value: _highContrast,
                    onChanged: (value) async {
                      setState(() => _highContrast = value);
                      await AACHelper.setHighContrast(value);
                      await AACHelper.speakWithAccessibility(
                        value ? 'High contrast mode enabled' : 'High contrast mode disabled',
                        announce: true,
                      );
                    },
                  ),
                  _buildToggleSetting(
                    title: 'Large Text',
                    subtitle: 'Makes text 30% larger for easier reading',
                    icon: CupertinoIcons.textformat_size,
                    value: _largeText,
                    onChanged: (value) async {
                      setState(() => _largeText = value);
                      await AACHelper.setLargeText(value);
                      await AACHelper.speakWithAccessibility(
                        value ? 'Large text enabled' : 'Large text disabled',
                        announce: true,
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader('🔊 Audio Feedback'),
                _buildSettingCard([
                  _buildToggleSetting(
                    title: 'Voice Feedback',
                    subtitle: 'Enable text-to-speech for all interactions',
                    icon: CupertinoIcons.speaker_2_fill,
                    value: _voiceFeedback,
                    onChanged: (value) async {
                      setState(() => _voiceFeedback = value);
                      await AACHelper.setVoiceFeedback(value);
                      if (value) {
                        await AACHelper.speakWithAccessibility('Voice feedback enabled');
                      }
                    },
                  ),
                  _buildToggleSetting(
                    title: 'Auto-Speak Symbols',
                    subtitle: 'Automatically speak symbols when selected',
                    icon: CupertinoIcons.speaker_1_fill,
                    value: _autoSpeak,
                    onChanged: (value) async {
                      setState(() => _autoSpeak = value);
                      await AACHelper.setAutoSpeak(value);
                      await AACHelper.speakWithAccessibility(
                        value ? 'Auto-speak enabled' : 'Auto-speak disabled',
                        announce: true,
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader('🎚️ Speech Controls'),
                _buildSettingCard([
                  _buildSliderSetting(
                    title: 'Speech Speed',
                    subtitle: 'Adjust how fast the voice speaks',
                    icon: CupertinoIcons.speedometer,
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (value) async {
                      setState(() => _speechRate = value);
                      await AACHelper.setSpeechRate(value);
                    },
                    onChangeEnd: (value) async {
                      await AACHelper.speakWithAccessibility('Speech speed adjusted');
                    },
                  ),
                  _buildSliderSetting(
                    title: 'Voice Pitch',
                    subtitle: 'Make the voice higher or lower',
                    icon: CupertinoIcons.waveform,
                    value: _speechPitch,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (value) async {
                      setState(() => _speechPitch = value);
                      await AACHelper.setSpeechPitch(value);
                    },
                    onChangeEnd: (value) async {
                      await AACHelper.speakWithAccessibility('Voice pitch adjusted');
                    },
                  ),
                  _buildSliderSetting(
                    title: 'Volume',
                    subtitle: 'Control speech volume level',
                    icon: CupertinoIcons.volume_up,
                    value: _speechVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) async {
                      setState(() => _speechVolume = value);
                      await AACHelper.setSpeechVolume(value);
                    },
                    onChangeEnd: (value) async {
                      await AACHelper.speakWithAccessibility('Volume adjusted');
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader('📳 Haptic Feedback'),
                _buildSettingCard([
                  _buildToggleSetting(
                    title: 'Haptic Feedback',
                    subtitle: 'Vibration feedback for button presses',
                    icon: CupertinoIcons.device_phone_portrait,
                    value: _hapticFeedback,
                    onChanged: (value) async {
                      setState(() => _hapticFeedback = value);
                      await AACHelper.setHapticFeedback(value);
                      if (value) {
                        await AACHelper.accessibleHapticFeedback();
                      }
                      await AACHelper.speakWithAccessibility(
                        value ? 'Haptic feedback enabled' : 'Haptic feedback disabled',
                        announce: true,
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader('🔊 Sound Effects'),
                _buildSettingCard([
                  _buildToggleSetting(
                    title: 'Sound Effects',
                    subtitle: 'Play sounds for button presses and interactions',
                    icon: CupertinoIcons.speaker_fill,
                    value: _soundEffects,
                    onChanged: (value) async {
                      setState(() => _soundEffects = value);
                      await AACHelper.setSoundEffects(value);
                      if (value) {
                        await AACHelper.playSound(SoundEffect.success);
                      }
                      await AACHelper.speakWithAccessibility(
                        value ? 'Sound effects enabled' : 'Sound effects disabled',
                        announce: true,
                      );
                    },
                  ),
                  _buildSliderSetting(
                    title: 'Sound Volume',
                    subtitle: 'Adjust sound effects volume level',
                    icon: CupertinoIcons.volume_up,
                    value: _soundVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) async {
                      setState(() => _soundVolume = value);
                      await AACHelper.setSoundVolume(value);
                    },
                    onChangeEnd: (value) async {
                      await AACHelper.playSound(SoundEffect.chime);
                    },
                  ),
                ]),

                const SizedBox(height: 30),
                _buildTestSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22 * AACHelper.getTextSizeMultiplier(),
          fontWeight: FontWeight.bold,
          color: AACHelper.isHighContrastEnabled 
              ? Colors.black 
              : AACHelper.childFriendlyColors[0],
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled 
            ? Colors.white 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      label: '$title, ${value ? 'enabled' : 'disabled'}, $subtitle',
      toggled: value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AACHelper.getAccessibleColors()[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AACHelper.getAccessibleColors()[0],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.w600,
                      color: AACHelper.isHighContrastEnabled 
                          ? Colors.black 
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                      color: AACHelper.isHighContrastEnabled 
                          ? Colors.black54 
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AACHelper.getAccessibleColors()[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Semantics(
      label: '$title, current value ${(value * 100).round()} percent, $subtitle',
      slider: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AACHelper.getAccessibleColors()[2].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AACHelper.getAccessibleColors()[2],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                          fontWeight: FontWeight.w600,
                          color: AACHelper.isHighContrastEnabled 
                              ? Colors.black 
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                          color: AACHelper.isHighContrastEnabled 
                              ? Colors.black54 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AACHelper.getAccessibleColors()[2],
                thumbColor: AACHelper.getAccessibleColors()[2],
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Material(
                color: Colors.transparent,
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AACHelper.isHighContrastEnabled
              ? [Colors.black, Colors.grey]
              : [
                  AACHelper.childFriendlyColors[3],
                  AACHelper.childFriendlyColors[4],
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🎯 Test Your Settings',
            style: TextStyle(
              fontSize: 20 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Test voice settings button',
            button: true,
            child: CupertinoButton(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.speaker_2_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Test Voice',
                    style: TextStyle(
                      fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onPressed: () async {
                await AACHelper.speakWithAccessibility(
                  'Hello! This is how your voice settings sound. Great job customizing your AAC app!',
                  haptic: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}