//lib/providers/tutor_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:brainiacz/services/firestore_services.dart';

class TutorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _tutors = [];
  Map<String, dynamic>? _selectedTutor;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get tutors => _tutors;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get selectedTutor => _selectedTutor;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;

  Future<void> fetchTutors() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final tutorsRef = FirebaseFirestore.instance.collection('tutors');
      final snapshot = await tutorsRef.get();
      _tutors = snapshot.docs.map((doc) => {
        'id': doc.id,
        'isAvailable': doc.data()['isAvailable'] ?? false,
        ...doc.data(),
      }).toList();
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching tutors: $error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchTutors(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current student ID
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final bool isStudent = currentUserId.isNotEmpty;
      
      // First, search for tutors matching the query in users collection
      // We'll look for tutors with the specialty subject or subjects matching the query
      final usersRef = FirebaseFirestore.instance.collection('users');
      
      // Query for specialty subject
      final specialtySnapshot = await usersRef
          .where('role', isEqualTo: 'tutor')
          .where('specialtySubject', isEqualTo: query)
          .get();

      // Query for subjects array
      final subjectsSnapshot = await usersRef
          .where('role', isEqualTo: 'tutor')
          .where('subjects', arrayContains: query)
          .get();

      final Map<String, Map<String, dynamic>> tutorMap = {};
      
      // Process tutors from specialty subject query
      for (var doc in specialtySnapshot.docs) {
        final data = doc.data();
        tutorMap[doc.id] = {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Tutor',
          'subjects': data['subjects'] ?? <String>[],
          'specialtySubject': data['specialtySubject'],
          'rating': data['averageRating'] ?? 0.0,
          'ratingCount': data['ratingCount'] ?? 0,
          'hadSessionWithCurrentStudent': false, // Default to false
          'uniqueStudentCount': 0,  // Default to 0
          'isAvailable': data['isAvailable'] ?? false, // Include availability status
          ...data,
        };
      }

      // Process tutors from subjects array query
      for (var doc in subjectsSnapshot.docs) {
        if (!tutorMap.containsKey(doc.id)) {
          final data = doc.data();
          tutorMap[doc.id] = {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Tutor',
            'subjects': data['subjects'] ?? <String>[],
            'specialtySubject': data['specialtySubject'],
            'rating': data['averageRating'] ?? 0.0,
            'ratingCount': data['ratingCount'] ?? 0,
            'hadSessionWithCurrentStudent': false, // Default to false
            'uniqueStudentCount': 0,  // Default to 0
            'isAvailable': data['isAvailable'] ?? false, // Include availability status
            ...data,
          };
        }
      }

      // Get session information for all tutors in parallel
      if (tutorMap.isNotEmpty) {
        final FirestoreService firestoreService = FirestoreService();
        
        // Create a list of futures to await them all at once
        List<Future> sessionInfoFutures = [];
        
        tutorMap.forEach((tutorId, tutorData) {
          // Add a future to get unique student count
          sessionInfoFutures.add(
            // ignore: avoid_types_as_parameter_names
            firestoreService.getTutorUniqueStudentCount(tutorId).then((count) {
              tutorMap[tutorId]!['uniqueStudentCount'] = count;
            })
          );
          
          // If the user is logged in as a student, check if they've had sessions with this tutor
          if (isStudent) {
            sessionInfoFutures.add(
              firestoreService.hasStudentHadSessionWithTutor(currentUserId, tutorId).then((hasHad) {
                tutorMap[tutorId]!['hadSessionWithCurrentStudent'] = hasHad;
              })
            );
          }
        });
        
        // Wait for all the future queries to complete
        await Future.wait(sessionInfoFutures);
      }

      // Convert the map to a list of tutors
      _tutors = tutorMap.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error searching tutors: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedTutor(Map<String, dynamic> tutor) {
    _selectedTutor = tutor;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String bio,
    required List<String> subjects,
    required double hourlyRate,
    String? education,
    String? experience,
    String? specialtySubject,
  }) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw 'User not authenticated';
    }
    
    final String userId = currentUserId;
    
    try {
      final Map<String, dynamic> updatedProfile = {
        'name': name,
        'email': email,
        'bio': bio,
        'subjects': subjects,
        'hourlyRate': hourlyRate,
        'education': education,
        'experience': experience,
        'specialtySubject': specialtySubject,
        'role': 'tutor',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.updateProfile(
        userId: userId,
        name: name,
        email: email,
        additionalData: {
          'bio': bio,
          'subjects': subjects,
          'hourlyRate': hourlyRate,
          'education': education,
          'experience': experience,
          'specialtySubject': specialtySubject,
          'role': 'tutor',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      final tutorRef = FirebaseFirestore.instance.collection('tutors').doc(userId);
      final tutorDoc = await tutorRef.get();
      
      if (tutorDoc.exists) {
        await tutorRef.update(updatedProfile);
      } else {
        updatedProfile['createdAt'] = FieldValue.serverTimestamp();
        await tutorRef.set(updatedProfile);
      }

      if (_selectedTutor != null) {
        _selectedTutor!.addAll(updatedProfile);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating tutor profile: $e");
      }
      rethrow;
    }
  }

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        _pendingRequests = await _firestoreService.getPendingRequests(userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching pending requests: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'accepted',
      });
      await fetchPendingRequests();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error accepting request: $e");
      }
      throw "Failed to accept request. Please try again.";
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'rejected',
      });
      await fetchPendingRequests();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error rejecting request: $e");
      }
      throw "Failed to reject request. Please try again.";
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Update in tutors collection
        await FirebaseFirestore.instance.collection('tutors').doc(userId).update({
          'isAvailable': isAvailable,
        });
        
        // Also update in users collection
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'isAvailable': isAvailable,
          });
        }
        
        if (kDebugMode) {
          print("Availability updated to: $isAvailable");
        }
        
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating availability: $e");
      }
      throw "Failed to update availability. Please try again.";
    }
  }
}