import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';
import '../utils/aac_helper.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen>
    with TickerProviderStateMixin {
  final LanguageService _languageService = LanguageService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  List<TTSVoice> _availableVoices = [];
  bool _isLoadingVoices = false;
  
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _selectedVoiceId = '';

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _loadCurrentSettings();
    _slideController.forward();
  }

  void _loadCurrentSettings() async {
    final ttsSettings = _languageService.ttsVoiceSettings;
    if (ttsSettings != null) {
      setState(() {
        _speechRate = ttsSettings.speechRate;
        _pitch = ttsSettings.pitch;
        _selectedVoiceId = ttsSettings.voiceId;
      });
    }
    await _loadAvailableVoices();
  }

  Future<void> _loadAvailableVoices() async {
    setState(() {
      _isLoadingVoices = true;
    });
    
    final voices = await _languageService.getAvailableVoices();
    
    setState(() {
      _availableVoices = voices;
      _isLoadingVoices = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.grey.shade50,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLanguageSection(),
                    const SizedBox(height: 24),
                    _buildVoiceSection(),
                    const SizedBox(height: 24),
                    _buildVoiceSettingsSection(),
                    const SizedBox(height: 24),
                    _buildTestSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_languageService.getLanguageFlag()} ${_languageService.translate('language_settings')}',
                style: TextStyle(
                  fontSize: 20 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.globe,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _languageService.translate('select_language'),
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._languageService.supportedLanguages.values.map(
            (language) => _buildLanguageItem(language),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(SupportedLanguage language) {
    final isSelected = _languageService.currentLanguage == language.code;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.transparent,
        border: isSelected ? Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 2,
        ) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
            ) : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              language.flag,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          language.nativeName,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF6C63FF) : Colors.black87,
          ),
        ),
        subtitle: Text(
          language.name,
          style: TextStyle(
            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: isSelected ? const Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: Color(0xFF6C63FF),
          size: 24,
        ) : null,
        onTap: () => _selectLanguage(language.code),
      ),
    );
  }

  Widget _buildVoiceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.speaker_2_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _languageService.translate('select_voice'),
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_isLoadingVoices)
                  const CupertinoActivityIndicator(),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_availableVoices.isEmpty && !_isLoadingVoices)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No voices available for this language',
                  style: TextStyle(
                    fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ..._availableVoices.map((voice) => _buildVoiceItem(voice)),
        ],
      ),
    );
  }

  Widget _buildVoiceItem(TTSVoice voice) {
    final isSelected = _selectedVoiceId == voice.id;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF6B6B).withOpacity(0.1) : Colors.transparent,
        border: isSelected ? Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          width: 2,
        ) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
            ) : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            voice.gender == 'female' ? CupertinoIcons.person_alt_circle_fill :
            voice.gender == 'male' ? CupertinoIcons.person_circle_fill :
            CupertinoIcons.speaker_2_fill,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 24,
          ),
        ),
        title: Text(
          voice.name,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${voice.gender.toUpperCase()} • ${voice.language}',
          style: TextStyle(
            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _testVoice(voice),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF51CF66),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.play_fill,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFFFF6B6B),
                size: 24,
              ),
            ],
          ],
        ),
        onTap: () => _selectVoice(voice.id),
      ),
    );
  }

  Widget _buildVoiceSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF51CF66), Color(0xFF4ECDC4)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _languageService.translate('voice_settings'),
                style: TextStyle(
                  fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSliderSetting(
            _languageService.translate('speech_rate'),
            _speechRate,
            0.0,
            1.0,
            CupertinoIcons.speedometer,
            (value) {
              setState(() {
                _speechRate = value;
              });
              _updateVoiceSettings();
            },
          ),
          const SizedBox(height: 20),
          _buildSliderSetting(
            _languageService.translate('pitch'),
            _pitch,
            0.5,
            2.0,
            CupertinoIcons.waveform_path_ecg,
            (value) {
              setState(() {
                _pitch = value;
              });
              _updateVoiceSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    IconData icon,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: const Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CupertinoSlider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF6C63FF),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.speaker_3_fill,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _languageService.translate('test_voice'),
            style: TextStyle(
              fontSize: 20 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            onPressed: _testCurrentSettings,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.play_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Test Current Voice',
                  style: TextStyle(
                    fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectLanguage(String languageCode) async {
    await _languageService.changeLanguage(languageCode);
    setState(() {
      _selectedVoiceId = '';
    });
    await _loadAvailableVoices();
    HapticFeedback.selectionClick();
  }

  void _selectVoice(String voiceId) {
    setState(() {
      _selectedVoiceId = voiceId;
    });
    _updateVoiceSettings();
    HapticFeedback.selectionClick();
  }

  void _updateVoiceSettings() {
    final settings = TTSVoiceSettings(
      languageCode: _languageService.currentLanguage,
      voiceId: _selectedVoiceId,
      speechRate: _speechRate,
      pitch: _pitch,
    );
    _languageService.updateTTSVoiceSettings(settings);
  }

  void _testVoice(TTSVoice voice) async {
    // Temporarily switch to this voice for testing
    final currentSettings = _languageService.ttsVoiceSettings;
    final testSettings = TTSVoiceSettings(
      languageCode: voice.language,
      voiceId: voice.id,
      speechRate: _speechRate,
      pitch: _pitch,
    );
    
    await _languageService.updateTTSVoiceSettings(testSettings);
    await _languageService.testVoice('Hello, this is a test of the voice settings.');
    
    // Restore original settings
    if (currentSettings != null) {
      await _languageService.updateTTSVoiceSettings(currentSettings);
    }
  }

  void _testCurrentSettings() async {
    final testText = _languageService.translate('hello') + 
        ', ' + 
        _languageService.translate('test_voice');
    await _languageService.testVoice(testText);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}