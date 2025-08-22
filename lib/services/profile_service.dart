import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profilesKey = 'user_profiles';
  static const String _currentProfileKey = 'current_profile_id';
  static const String _lastAccessKey = 'last_access_time';

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  List<UserProfile> _profiles = [];
  UserProfile? _currentProfile;

  List<UserProfile> get profiles => List.unmodifiable(_profiles);
  UserProfile? get currentProfile => _currentProfile;
  bool get hasProfiles => _profiles.isNotEmpty;
  bool get isChildMode => _currentProfile?.role == UserRole.child;
  bool get isCaregiverMode => _currentProfile?.role == UserRole.caregiver;

  Future<void> initialize() async {
    await _loadProfiles();
    await _loadCurrentProfile();
    
    // Create default child profile if none exists
    if (_profiles.isEmpty) {
      await createDefaultChildProfile();
    }
  }

  Future<UserProfile> createDefaultChildProfile() async {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Child Profile',
      role: UserRole.child,
      createdAt: DateTime.now(),
      settings: ProfileSettings(),
    );
    
    await addProfile(profile);
    await setCurrentProfile(profile.id);
    return profile;
  }

  Future<UserProfile> createCaregiverProfile({
    required String name,
    required String pin,
    String? avatarPath,
  }) async {
    final hashedPin = _hashPin(pin);
    
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: UserRole.caregiver,
      avatarPath: avatarPath,
      createdAt: DateTime.now(),
      settings: ProfileSettings(),
      pin: hashedPin,
    );
    
    await addProfile(profile);
    return profile;
  }

  Future<void> addProfile(UserProfile profile) async {
    _profiles.add(profile);
    await _saveProfiles();
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    final index = _profiles.indexWhere((p) => p.id == updatedProfile.id);
    if (index != -1) {
      _profiles[index] = updatedProfile;
      
      // Update current profile if it's the same
      if (_currentProfile?.id == updatedProfile.id) {
        _currentProfile = updatedProfile;
      }
      
      await _saveProfiles();
      await _saveCurrentProfile();
    }
  }

  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    
    // If deleted profile was current, switch to first available child profile
    if (_currentProfile?.id == profileId) {
      final childProfile = _profiles.firstWhere(
        (p) => p.role == UserRole.child,
        orElse: () => _profiles.isNotEmpty ? _profiles.first : throw Exception('No profiles available'),
      );
      await setCurrentProfile(childProfile.id);
    }
    
    await _saveProfiles();
  }

  Future<bool> authenticateCaregiver(String profileId, String pin) async {
    final profile = _profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw Exception('Profile not found'),
    );
    
    if (profile.role != UserRole.caregiver || profile.pin == null) {
      return false;
    }
    
    final hashedPin = _hashPin(pin);
    return hashedPin == profile.pin;
  }

  Future<void> setCurrentProfile(String profileId) async {
    final profile = _profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw Exception('Profile not found'),
    );
    
    _currentProfile = profile;
    await _saveCurrentProfile();
    await _updateLastAccess();
  }

  Future<void> switchToChildMode() async {
    final childProfile = _profiles.firstWhere(
      (p) => p.role == UserRole.child,
      orElse: () => throw Exception('No child profile found'),
    );
    
    await setCurrentProfile(childProfile.id);
  }

  Future<bool> requiresPinForAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAccess = prefs.getInt(_lastAccessKey);
    
    if (lastAccess == null) return false;
    
    final lastAccessTime = DateTime.fromMillisecondsSinceEpoch(lastAccess);
    final timeDifference = DateTime.now().difference(lastAccessTime);
    
    // Require PIN if more than 5 minutes have passed
    return timeDifference.inMinutes > 5;
  }

  Future<void> updateProfileSettings(String profileId, ProfileSettings settings) async {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      _profiles[index] = _profiles[index].copyWith(settings: settings);
      
      if (_currentProfile?.id == profileId) {
        _currentProfile = _profiles[index];
      }
      
      await _saveProfiles();
      await _saveCurrentProfile();
    }
  }

  Future<void> updateProfilePin(String profileId, String newPin) async {
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index != -1 && _profiles[index].role == UserRole.caregiver) {
      final hashedPin = _hashPin(newPin);
      _profiles[index] = _profiles[index].copyWith(pin: hashedPin);
      
      if (_currentProfile?.id == profileId) {
        _currentProfile = _profiles[index];
      }
      
      await _saveProfiles();
      await _saveCurrentProfile();
    }
  }

  List<UserProfile> getChildProfiles() {
    return _profiles.where((p) => p.role == UserRole.child).toList();
  }

  List<UserProfile> getCaregiverProfiles() {
    return _profiles.where((p) => p.role == UserRole.caregiver).toList();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_profilesKey);
      
      if (profilesJson != null) {
        final List<dynamic> profilesList = jsonDecode(profilesJson);
        _profiles = profilesList.map((json) => UserProfile.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading profiles: $e');
      _profiles = [];
    }
  }

  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = jsonEncode(_profiles.map((p) => p.toJson()).toList());
      await prefs.setString(_profilesKey, profilesJson);
    } catch (e) {
      print('Error saving profiles: $e');
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileId = prefs.getString(_currentProfileKey);
      
      if (profileId != null && _profiles.isNotEmpty) {
        _currentProfile = _profiles.firstWhere(
          (p) => p.id == profileId,
          orElse: () => _profiles.first,
        );
      } else if (_profiles.isNotEmpty) {
        _currentProfile = _profiles.first;
      }
    } catch (e) {
      print('Error loading current profile: $e');
      if (_profiles.isNotEmpty) {
        _currentProfile = _profiles.first;
      }
    }
  }

  Future<void> _saveCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentProfile != null) {
        await prefs.setString(_currentProfileKey, _currentProfile!.id);
      }
    } catch (e) {
      print('Error saving current profile: $e');
    }
  }

  Future<void> _updateLastAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastAccessKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error updating last access: $e');
    }
  }
}