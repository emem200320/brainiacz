import 'package:brainiacz/services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// ignore: unnecessary_import
import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get sessions => _sessions;
  bool get isLoading => _isLoading;

  // Fetch sessions for a specific student
  Future<void> fetchSessionsByStudentId(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _firestoreService.getSessionsByStudentId(studentId);
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching sessions: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch sessions for a specific tutor
  Future<void> fetchSessionsByTutorId() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      _sessions = await _firestoreService.getSessionsByTutorId(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel a session
  Future<void> cancelSession(String sessionId) async {
    try {
      await _firestoreService.updateSessionStatus(sessionId, 'cancelled');
      fetchSessionsByTutorId(); // Refresh the list
    } catch (e) {
      if (kDebugMode) {
        print("Error cancelling session: $e");
      }
    }
  }

  // Accept a session
  Future<void> acceptSession(String sessionId) async {
    try {
      await _firestoreService.updateSessionStatus(sessionId, 'accepted');
      fetchSessionsByTutorId(); // Refresh the list
    } catch (e) {
      if (kDebugMode) {
        print("Error accepting session: $e");
      }
    }
  }

  // Reject a session
  Future<void> rejectSession(String sessionId) async {
    try {
      await _firestoreService.updateSessionStatus(sessionId, 'rejected');
      fetchSessionsByTutorId(); // Refresh the list
    } catch (e) {
      if (kDebugMode) {
        print("Error rejecting session: $e");
      }
    }
  }

  // Send a tutoring request
  Future<void> sendRequest(Map<String, dynamic> request) async {
    try {
      await FirebaseFirestore.instance.collection('requests').add(request);
    } catch (e) {
      if (kDebugMode) {
        print("Error sending request: $e");
      }
    }
  }
}