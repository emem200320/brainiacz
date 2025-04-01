//lib/service/auth_services.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brainiacz/services/firestore_services.dart'; // Import FirestoreService

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService(); // Add FirestoreService

  // Signup with email and password
  Future<User?> signup({
    required String email,
    required String password,
    required String name,
    required String role, // Add role parameter
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Add user to Firestore
        await _firestoreService.addUser(
          userId: userCredential.user!.uid,
          name: name,
          email: email,
          role: role,
        );
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Signup failed. Please try again.";
    } catch (e) {
      throw "An unexpected error occurred. Please try again.";
    }
  }

  // Login with email and password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user's online status when they log in
      if (userCredential.user != null) {
        await _firestoreService.updateUserOnlineStatus(
          userId: userCredential.user!.uid,
          isOnline: true,
        );
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed. Please try again.";
    } catch (e) {
      throw "An unexpected error occurred. Please try again.";
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Update user's online status to offline before signing out
        await _firestoreService.updateUserOnlineStatus(
          userId: currentUser.uid,
          isOnline: false,
        );
      }
      
      await _auth.signOut();
    } catch (e) {
      throw "Logout failed. Please try again.";
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Fetch user role from Firestore
  Future<String> getUserRole(String userId) async {
    try {
      final userData = await _firestoreService.getUser(userId);
      return userData['role'] ?? 'student'; // Default to 'student' if role is not found
    } catch (e) {
      throw "Failed to fetch user role. Please try again.";
    }
  }
}