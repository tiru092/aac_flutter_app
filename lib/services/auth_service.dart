import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth status stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send verification email
  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
  }) async {
    try {
      // Update auth profile
      if (name != null || photoURL != null) {
        await _auth.currentUser?.updateDisplayName(name);
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }

      // Update Firestore user document
      if (_auth.currentUser != null) {
        final data = <String, dynamic>{};
        if (name != null) data['name'] = name;
        if (photoURL != null) data['photoURL'] = photoURL;
        
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Link user with UserProfile
  Future<void> linkUserWithProfile(String profileId) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'linkedProfiles': FieldValue.arrayUnion([profileId]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get user's profiles
  Future<List<String>> getUserProfiles() async {
    try {
      if (_auth.currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
            
        final data = doc.data();
        if (data != null && data.containsKey('linkedProfiles')) {
          return List<String>.from(data['linkedProfiles']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}