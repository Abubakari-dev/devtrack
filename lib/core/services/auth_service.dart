import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth State Changes
  Stream<User?> get user => _auth.authStateChanges();
  
  // Current user sync access
  User? get currentUser => _auth.currentUser;

  // Sign in with email/password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Sign-In Error: $e');
      rethrow;
    }
  }

  // Register with email/password and create Firestore profile
  Future<UserCredential?> signUp({
    required String email, 
    required String password, 
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'biometricsEnabled': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      return credential;
    } catch (e) {
      // Handle the Pigeon casting error if it happens during the signup call
      if (e.toString().contains('List<Object?>') && _auth.currentUser != null) {
        debugPrint('Handled Pigeon casting error in AuthService. Proceeding with Firestore creation.');
        
        final user = _auth.currentUser!;
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'biometricsEnabled': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        return null; // Credential couldn't be cast, but user exists
      }
      debugPrint('Sign-Up Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
