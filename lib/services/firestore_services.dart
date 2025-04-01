//lib/services/firestore_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new user
  Future<void> addUser({
    required String userId,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'role': role,
        'profileImageUrl': '', // Default empty profile image URL
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error adding user: $e");
      }
      throw "Failed to add user. Please try again.";
    }
  }

  // Get user data
  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>? ?? {}; // Return an empty map if data is null
      } else {
        throw "User not found.";
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user data: $e");
      }
      throw "Failed to fetch user data. Please try again.";
    }
  }

  // Fetch all tutors
  Future<List<Map<String, dynamic>>> getTutors() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('tutors').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (kDebugMode) {
          print("Tutor Data: $data");
        } // Debug log
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching tutors: $e");
      }
      throw "Failed to fetch tutors.";
    }
  }

  // Search tutors by subject
  Future<List<Map<String, dynamic>>> searchTutors(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('tutors')
          .where('subjects', arrayContains: query)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (kDebugMode) {
          print("Search Tutor Data: $data");
        } // Debug log
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error searching tutors: $e");
      }
      throw "Failed to search tutors.";
    }
  }

  // Fetch sessions for a specific student
  Future<List<Map<String, dynamic>>> getSessionsByStudentId(String studentId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('studentId', isEqualTo: studentId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (kDebugMode) {
          print("Session Data: $data");
        } // Debug log
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching sessions: $e");
      }
      throw "Failed to fetch sessions.";
    }
  }

  // Fetch sessions for a specific tutor
  Future<List<Map<String, dynamic>>> getSessionsByTutorId(String tutorId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('tutorId', isEqualTo: tutorId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (kDebugMode) {
          print("Session Data: $data");
        } // Debug log
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching sessions: $e");
      }
      throw "Failed to fetch sessions.";
    }
  }

  // Update session status
  Future<void> updateSessionStatus(String sessionId, String status) async {
    try {
      await _firestore.collection('requests').doc(sessionId).update({
        'status': status,
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating session status: $e");
      }
      throw "Failed to update session status.";
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String email,
    Map<String, dynamic>? additionalData,
  }) async {
    if (kDebugMode) {
      print("Updating profile for user: $userId");
      print("Name: $name");
      print("Email: $email");
      print("Additional data: $additionalData");
    }

    try {
      if (userId.isEmpty) {
        throw "User ID cannot be empty";
      }

      // Create the base data map
      final Map<String, dynamic> userData = {
        'name': name.trim(),
        'email': email.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add any additional data fields if provided
      if (additionalData != null) {
        // Filter out null values to prevent overwriting with null
        additionalData.forEach((key, value) {
          if (value != null) {
            // Handle nullable strings
            if (value is String) {
              userData[key] = value.trim();
            } else {
              userData[key] = value;
            }
          }
        });
      }
      
      if (kDebugMode) {
        print("Final user data for update: $userData");
      }
      
      // Check if the document exists first
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        if (kDebugMode) {
          print("Document exists, updating...");
        }
        // Update existing document
        await _firestore.collection('users').doc(userId).update(userData);
      } else {
        if (kDebugMode) {
          print("Document doesn't exist, creating new document...");
        }
        // Add creation timestamp for new documents
        userData['createdAt'] = FieldValue.serverTimestamp();
        
        // Create new document if it doesn't exist
        await _firestore.collection('users').doc(userId).set(userData);
      }
      
      if (kDebugMode) {
        print("Profile updated successfully for user: $userId");
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Firebase error updating profile: [${e.code}] ${e.message}");
      }
      throw "Firebase error: ${e.message}";
    } catch (e) {
      if (kDebugMode) {
        print("Error updating profile: $e");
      }
      throw "Failed to update profile: ${e.toString()}";
    }
  }

  // Check if a student already has a pending request with a tutor
  Future<bool> hasExistingPendingRequest(String studentId, String tutorId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('studentId', isEqualTo: studentId)
          .where('tutorId', isEqualTo: tutorId.trim())
          .where('status', isEqualTo: 'pending')
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print("Error checking existing requests: $e");
      }
      return false;
    }
  }
  
  // Send a tutor request
  Future<Map<String, dynamic>> sendTutorRequest({
    required String studentId,
    required String tutorId,
    required String subject,
    String? message,
    required DateTime sessionDate,
    required String sessionTime,
  }) async {
    try {
      // Debug the tutor ID to make sure it's correct
      if (kDebugMode) {
        print("About to send request with tutorId: $tutorId");
        print("Student ID: $studentId");
        print("Session Date: ${sessionDate.toIso8601String()}");
        print("Session Time: $sessionTime");
      }
      
      // Check if student already has a pending request with this tutor
      final hasExisting = await hasExistingPendingRequest(studentId, tutorId);
      
      if (hasExisting) {
        if (kDebugMode) {
          print("Student already has a pending request with this tutor");
        }
        return {
          'success': false,
          'message': 'You already have a pending request with this tutor.'
        };
      }
      
      // Get current timestamp
      
      // Create the request document with all required fields
      final requestData = {
        'studentId': studentId,
        'tutorId': tutorId.trim(), // Ensure no whitespace in ID
        'subject': subject,
        'message': message ?? 'I would like to connect with you for tutoring.',
        'status': 'pending',
        'sessionDate': sessionDate.toIso8601String(),
        'sessionTime': sessionTime,
        'requestedAt': FieldValue.serverTimestamp(), // Use server timestamp for consistent sorting
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add the document to Firestore and get the document reference
      final docRef = await _firestore.collection('requests').add(requestData);
      
      // Update the document with its ID
      await docRef.update({'id': docRef.id});
      
      if (kDebugMode) {
        print("Tutor request sent successfully with ID: ${docRef.id}");
        print("From student: $studentId to tutor: $tutorId");
        print("Request data: $requestData");
      }
      
      return {
        'success': true,
        'message': 'Request sent successfully!',
        'requestId': docRef.id
      };
    } catch (e) {
      if (kDebugMode) {
        print("Error sending tutor request: $e");
      }
      return {
        'success': false,
        'message': 'Failed to send tutor request: $e',
      };
    }
  }

  // Add a tutoring request
  Future<void> addRequest(Map<String, dynamic> request) async {
    try {
      await _firestore.collection('requests').add(request);
    } catch (e) {
      if (kDebugMode) {
        print("Error adding request: $e");
      }
      throw "Failed to send request.";
    }
  }

  // Fetch pending requests for a tutor
  Future<List<Map<String, dynamic>>> getPendingRequests(String tutorId) async {
    try {
      if (kDebugMode) {
        print("Fetching pending requests for tutor: $tutorId");
      }
      
      // First try an exact match
      QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('tutorId', isEqualTo: tutorId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (snapshot.docs.isEmpty) {
        // If no results, check if there are any requests at all
        final allRequests = await _firestore.collection('requests').get();
        if (kDebugMode) {
          print("No exact matches found. Total requests in collection: ${allRequests.docs.length}");
          for (var doc in allRequests.docs) {
            final data = doc.data();
            print("Request: ${doc.id} - tutorId: ${data['tutorId']}, status: ${data['status']}");
          }
        }
        
        // Try with trimmed tutorId
        snapshot = await _firestore
            .collection('requests')
            .get();
            
        // Filter manually to handle potential whitespace issues
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docTutorId = data['tutorId']?.toString().trim();
          final docStatus = data['status']?.toString().trim();
          
          return docTutorId == tutorId.trim() && docStatus == 'pending';
        }).toList();
        
        if (kDebugMode) {
          print("After manual filtering: ${filteredDocs.length} pending requests");
        }
        
        return filteredDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      }
      
      if (kDebugMode) {
        print("Found ${snapshot.docs.length} pending requests with exact match");
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Include the document ID in the returned data
        final result = {
          'id': doc.id,
          ...data,
        };
        
        if (kDebugMode) {
          print("Request ID: ${doc.id}");
          print("Request Data: $result");
        }
        
        return result;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching requests: $e");
      }
      throw "Failed to fetch requests.";
    }
  }

  // Update request status (accept/reject)
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      // Update the request status
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Note: Chat creation is now handled directly in TutorHomeScreen._acceptRequest
      // to ensure proper UI refresh and avoid duplicates
    } catch (e) {
      throw "Failed to update request status: $e";
    }
  }
  
  // Create a chat when a request is accepted

  // Fetch all users for admin management
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (kDebugMode) {
          print("User Data: $data");
        } // Debug log
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching users: $e");
      }
      throw "Failed to fetch users.";
    }
  }

  // Update user status (approve/suspend/remove)
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating user status: $e");
      }
      throw "Failed to update user status.";
    }
  }

  // Update tutor profile
  Future<void> updateTutorProfile(Map<String, dynamic> profile) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _firestore.collection('tutors').doc(userId).update(profile);
    } catch (e) {
      if (kDebugMode) {
        print("Error updating profile: $e");
      }
      throw "Failed to update profile.";
    }
  }

  // Fetch tutor details by ID
  Future<Map<String, dynamic>> getTutorById(String tutorId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('tutors').doc(tutorId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>? ?? {};
      } else {
        throw "Tutor not found.";
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching tutor details: $e");
      }
      throw "Failed to fetch tutor details.";
    }
  }

  // Fetch student details by ID
  Future<Map<String, dynamic>> getStudentById(String studentId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>? ?? {};
      } else {
        throw "Student not found.";
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching student details: $e");
      }
      throw "Failed to fetch student details.";
    }
  }

  // Get the number of unique students a tutor has had completed sessions with
  Future<int> getTutorUniqueStudentCount(String tutorId) async {
    try {
      if (kDebugMode) {
        print("Fetching unique student count for tutor ID: $tutorId");
      }
      
      // Query sessions where this tutor was the recipient (tutor)
      final QuerySnapshot snapshot = await _firestore
          .collection('sessions')
          .where('recipientId', isEqualTo: tutorId)
          // Include all relevant session statuses
          .where('status', whereIn: ['completed', 'active'])
          .get();
      
      if (kDebugMode) {
        print("Found ${snapshot.docs.length} session records for tutor $tutorId");
      }
      
      // Extract unique student IDs from the sessions
      Set<String> uniqueStudentIds = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (data.containsKey('requesterId') && data['requesterId'] != null) {
          uniqueStudentIds.add(data['requesterId'] as String);
          if (kDebugMode) {
            print("Added student ID: ${data['requesterId']} to unique set");
          }
        }
      }
      
      if (kDebugMode) {
        print("Unique student count for tutor $tutorId: ${uniqueStudentIds.length}");
      }
      
      return uniqueStudentIds.length;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching tutor unique student count: $e");
      }
      return 0; // Return 0 on error instead of throwing
    }
  }

  // Check if a student has had sessions with a specific tutor
  Future<bool> hasStudentHadSessionWithTutor(String studentId, String tutorId) async {
    try {
      if (kDebugMode) {
        print("Checking if student $studentId had session with tutor $tutorId");
      }
      
      final QuerySnapshot snapshot = await _firestore
          .collection('sessions')
          .where('requesterId', isEqualTo: studentId)
          .where('recipientId', isEqualTo: tutorId)
          // Include all relevant session statuses
          .where('status', whereIn: ['completed', 'active'])
          .limit(1)  // We only need to know if there's at least one
          .get();
      
      if (kDebugMode) {
        print("Found ${snapshot.docs.length} matching sessions");
      }
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print("Error checking if student had session with tutor: $e");
      }
      return false; // Return false on error
    }
  }

  // Update user's online status
  Future<void> updateUserOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating user online status: $e");
      }
      throw "Failed to update online status. Please try again.";
    }
  }
  
  // Report a user
  Future<void> reportUser({
    required String reporterId, 
    required String reporterName,
    required String reportedUserId,
    required String reportedUserName,
    required String reportedUserRole,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      // Add the report to the reports collection
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reportedUserRole': reportedUserRole,
        'reason': reason,
        'additionalInfo': additionalInfo,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Get count of pending reports for this user
      final reportsQuery = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Update the user's report count
      await _firestore.collection('users').doc(reportedUserId).update({
        'reportCount': reportsQuery.docs.length,
      });
      
      if (kDebugMode) {
        print("User reported successfully. Total reports: ${reportsQuery.docs.length}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error reporting user: $e");
      }
      throw "Failed to report user. Please try again.";
    }
  }
  
  // Get count of reports for a user
  Future<int> getUserReportCount(String userId) async {
    try {
      final reportsQuery = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return reportsQuery.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting user report count: $e");
      }
      return 0;
    }
  }
}