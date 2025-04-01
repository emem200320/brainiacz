// lib/providers/auth_providers.dart
import 'package:brainiacz/services/auth_services.dart';
import 'package:brainiacz/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  String? _userRole;
  bool _isLoggedIn = false;
  User? _user;
  List<Map<String, dynamic>> _users = []; // List to store all users

  String? get userRole => _userRole;
  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  List<Map<String, dynamic>> get users => _users; // Getter for users

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Signup
  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final User? user = await _authService.signup(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      if (user != null) {
        await _firestoreService.addUser(
          userId: user.uid,
          name: name,
          email: email,
          role: role,
        );
        _user = user;
        _userRole = role;
        _isLoggedIn = true;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Signup failed. Please try again.";
    } catch (e) {
      throw "An unexpected error occurred. Please try again.";
    }
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final User? user = await _authService.login(email: email, password: password);
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        
        // Check if user is banned
        if (userData['isBanned'] == true) {
          // Automatically sign out the user
          await _authService.logout();
          throw "This account has been banned. Please contact support for assistance.";
        }
        
        if (userData['role'] == role) {
          _user = user;
          _userRole = role;
          _isLoggedIn = true;
          notifyListeners();
        } else {
          throw "Unauthorized access. Your role does not match.";
        }
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed. Please try again.";
    } catch (e) {
      throw e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      _userRole = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      throw "Logout failed. Please try again.";
    }
  }

  // Check login status
  Future<void> checkLoginStatus() async {
    try {
      final User? user = _authService.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        
        // Check if user is banned
        if (userData['isBanned'] == true) {
          // Automatically sign out the user
          await _authService.logout();
          _user = null;
          _userRole = null;
          _isLoggedIn = false;
          notifyListeners();
          throw "This account has been banned. Please contact support for assistance.";
        }
        
        _user = user;
        _userRole = userData['role'];
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      // Don't throw here to avoid disrupting app startup
      if (e.toString() != "This account has been banned. Please contact support for assistance.") {
        if (kDebugMode) {
          print("Failed to check login status: $e");
        }
      }
    }
  }

  // Fetch all users (for admin)
  Future<void> fetchUsers() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      _users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'id': doc.id, // Include the document ID
          ...data, // Spread the rest of the data
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching users: $e");
      }
      throw "Failed to fetch users. Please try again.";
    }
  }

  // Approve a user (for admin)
  Future<void> approveUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'status': 'approved'});
      await fetchUsers(); // Refresh the list
    } catch (e) {
      if (kDebugMode) {
        print("Error approving user: $e");
      }
      throw "Failed to approve user. Please try again.";
    }
  }

  // Suspend a user (for admin)
  Future<void> suspendUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'status': 'suspended'});
      await fetchUsers(); // Refresh the list
    } catch (e) {
      if (kDebugMode) {
        print("Error suspending user: $e");
      }
      throw "Failed to suspend user. Please try again.";
    }
  }

  // Remove a user (for admin)
  Future<void> removeUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      await fetchUsers(); // Refresh the list
    } catch (e) {
      if (kDebugMode) {
        print("Error removing user: $e");
      }
      throw "Failed to remove user. Please try again.";
    }
  }
}