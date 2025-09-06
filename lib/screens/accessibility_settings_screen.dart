import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/aac_helper.dart';
import '../services/language_service.dart';
import '../screens/language_settings_screen.dart';
import '../screens/voice_settings_screen.dart';
import '../screens/backup_management_screen.dart';
import '../models/user_profile.dart';
import '../services/connectivity_service.dart';
import '../widgets/connectivity_indicator.dart';
import '../screens/data_availability_screen.dart';
import '../screens/offline_features_screen.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  final LanguageService _languageService = LanguageService();
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  bool _isVoiceFeedbackEnabled = true;
  bool _isHapticFeedbackEnabled = true;
  bool _isAutoSpeakEnabled = false;
  bool _isSoundEffectsEnabled = true;
  double _soundVolume = 1.0;
  late UserProfile _currentUser; // Add current user

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _currentUser = UserProfile( // Initialize with a default user for now
      id: 'temp_user',
      name: 'Temporary User',
      role: UserRole.child,
      createdAt: DateTime.now(),
      settings: ProfileSettings(),
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isHighContrastEnabled = AACHelper.isHighContrastEnabled;
      _isLargeTextEnabled = AACHelper.isLargeTextEnabled;
      _isVoiceFeedbackEnabled = AACHelper.isVoiceFeedbackEnabled;
      _isHapticFeedbackEnabled = AACHelper.isHapticFeedbackEnabled;
      _isAutoSpeakEnabled = AACHelper.isAutoSpeakEnabled;
      _isSoundEffectsEnabled = AACHelper.isSoundEffectsEnabled;
      _soundVolume = AACHelper.soundVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF4ECDC4),
        middle: Text(
          '♿ Accessibility Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHighContrastToggle(),
            const SizedBox(height: 16),
            _buildLargeTextToggle(),
            const SizedBox(height: 16),
            _buildVoiceFeedbackToggle(),
            const SizedBox(height: 16),
            _buildHapticFeedbackToggle(),
            const SizedBox(height: 16),
            _buildAutoSpeakToggle(),
            const SizedBox(height: 16),
            _buildSoundEffectsToggle(),
            const SizedBox(height: 16),
            _buildSoundVolumeSlider(),
            const SizedBox(height: 16),
            _buildTestSection(),
            const SizedBox(height: 16),
            _buildLanguageSection(),
            const SizedBox(height: 16),
            _buildVoiceSettingsSection(),
            const SizedBox(height: 16),
            _buildBackupSection(),
            const SizedBox(height: 16),
            _buildConnectivitySection(),
            const SizedBox(height: 16),
            _buildDataAvailabilitySection(),
            const SizedBox(height: 16),
            _buildOfflineFeaturesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighContrastToggle() {
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
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          activeColor: const Color(0xFF4ECDC4),
          title: Text(
            'High Contrast Mode',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Enhanced visibility with bold colors',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black54 
                  : Colors.grey[600],
            ),
          ),
          value: _isHighContrastEnabled,
          onChanged: (value) async {
            setState(() {
              _isHighContrastEnabled = value;
            });
            await AACHelper.setHighContrast(value);
          },
        ),
      ),
    );
  }

  Widget _buildLargeTextToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          activeColor: const Color(0xFF4ECDC4),
          title: Text(
            'Large Text',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Increase text size for better readability',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey[600],
            ),
          ),
          value: _isLargeTextEnabled,
          onChanged: (value) async {
            setState(() {
              _isLargeTextEnabled = value;
            });
            await AACHelper.setLargeText(value);
          },
        ),
      ),
    );
  }

  Widget _buildVoiceFeedbackToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          activeColor: const Color(0xFF4ECDC4),
          title: Text(
            'Voice Feedback',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Speak button labels and actions',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey[600],
            ),
          ),
          value: _isVoiceFeedbackEnabled,
          onChanged: (value) async {
            setState(() {
              _isVoiceFeedbackEnabled = value;
            });
            await AACHelper.setVoiceFeedback(value);
          },
        ),
      ),
    );
  }

  Widget _buildHapticFeedbackToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          activeColor: const Color(0xFF4ECDC4),
          title: Text(
            'Haptic Feedback',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Vibrations for interactions',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey[600],
            ),
          ),
          value: _isHapticFeedbackEnabled,
          onChanged: (value) async {
            setState(() {
              _isHapticFeedbackEnabled = value;
            });
            await AACHelper.setHapticFeedback(value);
          },
        ),
      ),
    );
  }

  Widget _buildAutoSpeakToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          activeColor: const Color(0xFF4ECDC4),
          title: Text(
            'Auto Speak',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Automatically speak selected symbols',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey[600],
            ),
          ),
          value: _isAutoSpeakEnabled,
          onChanged: (value) async {
            setState(() {
              _isAutoSpeakEnabled = value;
            });
            await AACHelper.setAutoSpeak(value);
          },
        ),
      ),
    );
  }

  Widget _buildSoundEffectsToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          activeColor: const Color(0xFF4ECDC4),
          title: Text(
            'Sound Effects',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Play sounds for interactions',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey[600],
            ),
          ),
          value: _isSoundEffectsEnabled,
          onChanged: (value) async {
            setState(() {
              _isSoundEffectsEnabled = value;
            });
            await AACHelper.setSoundEffects(value);
          },
        ),
      ),
    );
  }

  Widget _buildSoundVolumeSlider() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            'Sound Volume',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4ECDC4),
              thumbColor: const Color(0xFF4ECDC4),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _soundVolume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) async {
                setState(() {
                  _soundVolume = value;
                });
                await AACHelper.setSoundVolume(value);
              },
            ),
          ),
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
                  AACHelper.childFriendlyColors[3]!,
                  AACHelper.childFriendlyColors[4]!,
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

  Widget _buildLanguageSection() {
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
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AACHelper.getAccessibleColors()[2].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _languageService.getLanguageFlag(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            'Language & Voice',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            '${_languageService.getLanguageName()} • Configure voice settings',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black54 
                  : Colors.grey[600],
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey,
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const LanguageSettingsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVoiceSettingsSection() {
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
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.mic,
              color: Color(0xFF4ECDC4),
              size: 24,
            ),
          ),
          title: Text(
            'Custom Voices',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Record and manage custom voices',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black54 
                  : Colors.grey[600],
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey,
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const VoiceSettingsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
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
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AACHelper.getAccessibleColors()[2].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.archivebox_fill,
                  color: Color(0xFF6C63FF),
                  size: 24,
                ),
              ),
              title: Text(
                'Backup & Restore',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Save and restore your app data locally',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              trailing: const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => BackupManagementScreen(currentUser: _currentUser), // Pass current user
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.cloud,
                  color: Color(0xFF4ECDC4),
                  size: 24,
                ),
              ),
              title: Text(
                'Cloud Sync',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Sync data across all your devices',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              trailing: const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
              ),
              onTap: () {
                // Cloud sync functionality would be implemented here
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivitySection() {
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
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.wifi,
                  color: Color(0xFF4ECDC4),
                  size: 24,
                ),
              ),
              title: Text(
                'Connectivity & Offline Settings',
                style: TextStyle(
                  fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.w600,
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black 
                      : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Configure connectivity monitoring and offline features',
                style: TextStyle(
                  fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                  color: AACHelper.isHighContrastEnabled 
                      ? Colors.black54 
                      : Colors.grey[600],
                ),
              ),
              trailing: const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
              ),
              onTap: () {
                _showConnectivitySettings();
              },
            ),
            const Divider(height: 1),
            // Real-time connectivity status display
            StreamBuilder<ConnectivityStatus>(
              stream: ConnectivityService.instance.statusStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                
                final status = snapshot.data!;
                final isOnline = status.isOnline;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isOnline ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.wifi_slash,
                      color: isOnline ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Current Status: ${isOnline ? 'Online' : 'Offline'}',
                    style: TextStyle(
                      fontSize: 15 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.w500,
                      color: AACHelper.isHighContrastEnabled 
                          ? Colors.black 
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    isOnline 
                        ? 'Connection quality: ${status.connectionQuality.name.toUpperCase()}'
                        : 'All core features available offline',
                    style: TextStyle(
                      fontSize: 13 * AACHelper.getTextSizeMultiplier(),
                      color: AACHelper.isHighContrastEnabled 
                          ? Colors.black54 
                          : Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    _showConnectivityDetails();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectivitySettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            'Connectivity Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          message: const Text('Configure how the app monitors and displays connectivity status'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Show Connectivity Indicator'),
              onPressed: () async {
                Navigator.pop(context);
                await ConnectivityService.instance.setIndicatorVisible(true);
                if (mounted) {
                  _showSettingsConfirmation('Connectivity indicator enabled');
                }
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Hide Connectivity Indicator'),
              onPressed: () async {
                Navigator.pop(context);
                await ConnectivityService.instance.setIndicatorVisible(false);
                if (mounted) {
                  _showSettingsConfirmation('Connectivity indicator disabled');
                }
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Enable Background Monitoring'),
              onPressed: () async {
                Navigator.pop(context);
                await ConnectivityService.instance.setBackgroundMonitoring(true);
                if (mounted) {
                  _showSettingsConfirmation('Background monitoring enabled');
                }
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Disable Background Monitoring'),
              onPressed: () async {
                Navigator.pop(context);
                await ConnectivityService.instance.setBackgroundMonitoring(false);
                if (mounted) {
                  _showSettingsConfirmation('Background monitoring disabled');
                }
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('View Connectivity Statistics'),
              onPressed: () {
                Navigator.pop(context);
                _showConnectivityStatistics();
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showConnectivityDetails() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<ConnectivityStatus>(
          stream: ConnectivityService.instance.statusStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CupertinoAlertDialog(
                title: Text('Loading...'),
                content: Text('Fetching connectivity information'),
              );
            }
            
            final status = snapshot.data!;
            
            return CupertinoAlertDialog(
              title: const Text('Connectivity Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text('Status: ${status.isOnline ? 'Online' : 'Offline'}'),
                  Text('Connection Type: ${status.connectionType.name}'),
                  Text('Quality: ${status.connectionQuality.name.toUpperCase()}'),
                  if (status.lastConnected != null)
                    Text('Last Connected: ${_formatDateTime(status.lastConnected!)}'),
                  if (status.lastDisconnected != null)
                    Text('Last Disconnected: ${_formatDateTime(status.lastDisconnected!)}'),
                  const SizedBox(height: 10),
                  const Text(
                    'All core AAC features work offline. Online features include cloud sync and backup.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConnectivityStatistics() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ConnectivityService.instance.getStatistics(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CupertinoAlertDialog(
                title: Text('Loading...'),
                content: Text('Fetching connectivity statistics'),
              );
            }
            
            final stats = snapshot.data!;
            
            return CupertinoAlertDialog(
              title: const Text('Connectivity Statistics'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text('Total Checks: ${stats['totalChecks'] ?? 0}'),
                  Text('Successful Connections: ${stats['successfulConnections'] ?? 0}'),
                  Text('Failed Connections: ${stats['failedConnections'] ?? 0}'),
                  Text('Average Response Time: ${stats['averageResponseTime']?.toStringAsFixed(1) ?? 'N/A'} ms'),
                  Text('Uptime: ${((stats['uptime'] ?? 0) * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 10),
                  const Text(
                    'Statistics are collected to improve offline experience.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Reset Statistics'),
                  onPressed: () async {
                    await ConnectivityService.instance.resetStatistics();
                    Navigator.pop(context);
                    if (mounted) {
                      _showSettingsConfirmation('Statistics reset successfully');
                    }
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsConfirmation(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Settings Updated'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataAvailabilitySection() {
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
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.archivebox_fill,
              color: Colors.purple,
              size: 24,
            ),
          ),
          title: Text(
            'Data Availability & Caching',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Configure intelligent pre-caching for optimal offline experience',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black54 
                  : Colors.grey[600],
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey,
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const DataAvailabilityScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOfflineFeaturesSection() {
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
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.rocket_fill,
              color: Colors.indigo,
              size: 24,
            ),
          ),
          title: Text(
            'Advanced Offline Features',
            style: TextStyle(
              fontSize: 17 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.w600,
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black 
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Analytics, insights, achievements, and personalized recommendations',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled 
                  ? Colors.black54 
                  : Colors.grey[600],
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey,
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const OfflineFeaturesScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}