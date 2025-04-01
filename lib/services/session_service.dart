// lib/services/session_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import 'package:rxdart/rxdart.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton instance
  static final SessionService _instance = SessionService._internal();

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  // Stream controller for active session timer
  StreamController<Duration>? _timerController;
  Timer? _sessionTimer;
  SessionModel? _currentSession;

  // Stream for session rating
  final _ratingSubject = BehaviorSubject<Map<String, dynamic>?>();
  Map<String, dynamic>? _sessionToRate;

  // Get chat ID consistently regardless of who initiated
  String getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '$userId1-$userId2'
        : '$userId2-$userId1';
  }

  // Request a new session - Creates a session with requester, recipient and participants array
  Future<void> requestSession({
    required String recipientId,
    required int durationMinutes,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      final chatId = getChatId(currentUserId, recipientId);
      final requestTime = DateTime.now();

      // Create session document
      final sessionDoc = _firestore.collection('sessions').doc();

      // Create session model
      final session = SessionModel(
        id: sessionDoc.id,
        requesterId: currentUserId,
        recipientId: recipientId,
        durationMinutes: durationMinutes,
        requestTime: requestTime,
        status: SessionStatus.requested,
      );

      // Save to Firestore
      await sessionDoc.set(session.toMap());

      // Add system message to chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'System',
        'receiverId': recipientId,
        'content': 'Session request: $durationMinutes minutes',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sessionId': sessionDoc.id,
      });

      if (kDebugMode) {
        print('Session request sent: ${sessionDoc.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting session: $e');
      }
      rethrow;
    }
  }

  // Accept a session request
  Future<void> acceptSession(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) throw 'User not authenticated';

      // Get session data
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) throw 'Session not found';

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final SessionModel session =
          SessionModel.fromMap({...sessionData, 'id': sessionId});

      // Verify current user is the recipient
      if (session.recipientId != currentUserId) {
        throw 'Unauthorized: Not the session recipient';
      }

      // Update session status
      final updatedSession = session.copyWith(
        status: SessionStatus.active,
        startTime: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .update(updatedSession.toMap());

      // Add system message to chat
      final chatId = getChatId(session.requesterId, session.recipientId);
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'System',
        'receiverId': session.requesterId,
        'content': 'Session started: ${session.durationMinutes} minutes',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sessionId': sessionId,
      });

      // Start the session timer
      startSessionTimer(updatedSession);

      if (kDebugMode) {
        print('Session accepted: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting session: $e');
      }
      rethrow;
    }
  }

  // Decline a session request
  Future<void> declineSession(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      // Get session data
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) throw 'Session not found';

      final sessionData = sessionDoc.data() as Map<String, dynamic>;

      // Ensure current user is the recipient
      if (sessionData['recipientId'] != currentUserId) {
        throw 'Only the recipient can decline this session';
      }

      final requesterId = sessionData['requesterId'] as String;
      final chatId = getChatId(currentUserId, requesterId);

      // Update session status
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': SessionStatus.cancelled.toString().split('.').last,
      });

      // Add system message to chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'System',
        'receiverId': requesterId,
        'content': 'Session request declined',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sessionId': sessionId,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error declining session: $e');
      }
      rethrow;
    }
  }

  // Toggle pause/resume for the session
  Future<void> togglePauseSession(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) throw 'User not authenticated';

      // Get session data
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) throw 'Session not found';

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final SessionModel session =
          SessionModel.fromMap({...sessionData, 'id': sessionId});

      // Ensure current user is participant
      final bool isRequester = session.requesterId == currentUserId;
      final bool isRecipient = session.recipientId == currentUserId;

      if (!isRequester && !isRecipient) {
        throw 'You are not a participant in this session';
      }

      final otherUserId =
          isRequester ? session.recipientId : session.requesterId;
      final chatId = getChatId(currentUserId, otherUserId);

      // Add notification message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'System',
        'content': 'Session cannot be paused - feature has been removed.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling session pause: $e');
      }
      rethrow;
    }
  }

  // End an active session
  Future<void> endSession(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      // Get session data
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) throw 'Session not found';

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final SessionModel session =
          SessionModel.fromMap({...sessionData, 'id': sessionId});

      // Determine if current user is requester or recipient
      final bool isRequester = session.requesterId == currentUserId;
      final bool isRecipient = session.recipientId == currentUserId;

      if (!isRequester && !isRecipient) {
        throw 'You are not a participant in this session';
      }

      // Update elapsed seconds before ending
      int finalElapsedSeconds = session.elapsedSeconds;
      if (session.startTime != null && !session.isPaused) {
        final now = DateTime.now();
        finalElapsedSeconds = now.difference(session.startTime!).inSeconds;
      }

      // Update session
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': SessionStatus.completed.toString().split('.').last,
        'endTime': FieldValue.serverTimestamp(),
        'elapsedSeconds': finalElapsedSeconds,
        'requesterPaused': false,
        'recipientPaused': false,
      });

      // Stop timer if this was the active session
      if (_currentSession?.id == sessionId) {
        _stopTimer();
      }

      // Add system message about session end
      final otherUserId =
          isRequester ? session.recipientId : session.requesterId;
      final chatId = getChatId(currentUserId, otherUserId);

      // Format duration for display
      final totalSeconds = session.durationMinutes * 60;
      final durationFormatted = formatDuration(Duration(seconds: totalSeconds));

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'System',
        'receiverId': otherUserId,
        'content': 'Session ended. Duration: $durationFormatted',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sessionId': sessionId,
      });

      // Show rating dialog if user is student (requester) and session has not been rated yet
      if (isRequester) {
        // Check if the session has already been rated
        final bool hasRating = sessionData['tutorRating'] != null;

        if (!hasRating) {
          _sessionToRate = {
            'sessionId': sessionId,
            'tutorId': session.recipientId,
            'duration': durationFormatted,
          };
          _ratingSubject.add(_sessionToRate);
        } else {
          if (kDebugMode) {
            print(
                'Session $sessionId has already been rated. Skipping rating dialog.');
          }
          // Add this to ensure rating dialog doesn't show
          _sessionToRate = null;
          _ratingSubject.add(null);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ending session: $e');
      }
      rethrow;
    }
  }

  // Start session timer
  void startSessionTimer(SessionModel session) {
    // Stop any existing timer
    _stopTimer();

    // Store current session
    _currentSession = session;

    // Only start timer if session is active and not paused
    if (session.status != SessionStatus.active || session.isPaused) {
      if (kDebugMode) {
        print(
            'Not starting timer: session is ${session.status} and isPaused=${session.isPaused}');
      }

      // Create a timer controller but don't start counting down yet
      _timerController = StreamController<Duration>.broadcast();
      _timerController?.add(session.remainingTime);
      return;
    }

    // Create a new timer controller
    _timerController = StreamController<Duration>.broadcast();

    // Calculate initial remaining time
    final initialRemaining = session.remainingTime;

    if (kDebugMode) {
      print(
          'Starting session timer with initial remaining time: ${formatDuration(initialRemaining)}');
    }

    // Send initial time
    _timerController?.add(initialRemaining);

    // Create a periodic timer to update every second
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession == null) {
        _stopTimer();
        return;
      }

      // Refresh session data from Firestore occasionally to sync with server
      if (timer.tick % 10 == 0) {
        _refreshSessionData(_currentSession!.id);
      }

      // Check if session is paused - if so, don't count down
      if (_currentSession!.isPaused) {
        _timerController?.add(_currentSession!.remainingTime);
        return;
      }

      // Update remaining time
      final remaining =
          _currentSession!.remainingTime - const Duration(seconds: 1);

      if (kDebugMode && timer.tick % 30 == 0) {
        if (kDebugMode) {
          print(
              'Timer tick: ${timer.tick}, Remaining: ${formatDuration(remaining)}');
        }
      }

      if (remaining.inSeconds <= 0) {
        // Session time is up
        _timerController?.add(Duration.zero);
        endSession(_currentSession!.id);
        _stopTimer();
      } else {
        // Update time
        _timerController?.add(remaining);
      }
    });
  }

  // Add this method to refresh session data periodically
  Future<void> _refreshSessionData(String sessionId) async {
    try {
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return;

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final refreshedSession =
          SessionModel.fromMap({...sessionData, 'id': sessionId});

      // Update local copy of session data
      _currentSession = refreshedSession;

      // If session is active but timer is not running, restart timer
      if (_sessionTimer == null &&
          refreshedSession.status == SessionStatus.active) {
        startSessionTimer(refreshedSession);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing session data: $e');
      }
    }
  }

  // Stop timer
  void _stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _timerController?.close();
    _timerController = null;
    _currentSession = null;
  }

  // Get session timer stream
  Stream<Duration>? get sessionTimerStream => _timerController?.stream;

  // Get active session for a chat
  Stream<SessionModel?> getActiveSession(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('sessions')
        .where('status',
            isEqualTo: SessionStatus.active.toString().split('.').last)
        .where('requesterId', isEqualTo: currentUserId)
        .where('recipientId', isEqualTo: otherUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Check if user is recipient
        return null;
      }
      final data = snapshot.docs.first.data();
      return SessionModel.fromMap({...data, 'id': snapshot.docs.first.id});
    });
  }

  // Get session request for a chat (if any)
  Stream<SessionModel?> getSessionRequest(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('sessions')
        .where('status',
            isEqualTo: SessionStatus.requested.toString().split('.').last)
        .where('recipientId', isEqualTo: currentUserId)
        .where('requesterId', isEqualTo: otherUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // No active request
        return null;
      }
      final data = snapshot.docs.first.data();
      return SessionModel.fromMap({...data, 'id': snapshot.docs.first.id});
    });
  }

  // Submit a rating for a tutor after a completed session
  Future<void> submitTutorRating({
    required String sessionId,
    required double rating,
    required String tutorId,
  }) async {
    try {
      if (kDebugMode) {
        print('Submitting tutor rating: $rating for session $sessionId');
      }

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      // Get the session data
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) throw 'Session not found';

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      if (sessionData['status'] != 'completed') {
        throw 'Can only rate completed sessions';
      }

      // Verify current user is the student who requested the session
      if (sessionData['requesterId'] != currentUserId) {
        throw 'Only the student who requested the session can submit a rating';
      }

      // Get the tutor's ID from the session
      final String tutorId = sessionData['recipientId'] as String;
      if (tutorId.isEmpty) {
        throw 'Tutor ID not found in session';
      }

      // Update the session with the rating
      await _firestore.collection('sessions').doc(sessionId).update({
        'tutorRating': rating,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Add the rating to the tutor's profile
      // First, get the current ratings
      final tutorDoc = await _firestore.collection('users').doc(tutorId).get();
      if (!tutorDoc.exists) throw 'Tutor profile not found';

      final tutorData = tutorDoc.data() as Map<String, dynamic>;

      // Get current rating count - check all possible field names
      final int currentRatingCount = tutorData['ratingCount'] as int? ?? 0;

      // Get current average rating - check all possible field names
      double currentAverageRating = 0.0;
      if (tutorData.containsKey('averageRating') &&
          tutorData['averageRating'] != null) {
        currentAverageRating = (tutorData['averageRating'] as num).toDouble();
      } else if (tutorData.containsKey('rating') &&
          tutorData['rating'] != null) {
        currentAverageRating = (tutorData['rating'] as num).toDouble();
      }

      if (kDebugMode) {
        print(
            'Current tutor rating data: count=$currentRatingCount, average=$currentAverageRating');
      }

      // Calculate the new average
      final int newRatingCount = currentRatingCount + 1;
      final double newAverageRating =
          ((currentAverageRating * currentRatingCount) + rating) /
              newRatingCount;

      if (kDebugMode) {
        print(
            'New rating data: count=$newRatingCount, average=$newAverageRating');
      }

      // Update the tutor's profile with BOTH rating fields for consistency
      await _firestore.collection('users').doc(tutorId).update({
        'ratingCount': newRatingCount,
        'rating': newAverageRating,
        'averageRating': newAverageRating,
        'lastRatingAt': FieldValue.serverTimestamp(),
      });

      // Add a record to the ratings collection
      await _firestore.collection('ratings').add({
        'tutorId': tutorId,
        'studentId': currentUserId,
        'sessionId': sessionId,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the rating state and ensure dialog is removed
      _sessionToRate = null;
      _ratingSubject.add(null);

      // Update session to prevent rating dialog from showing again
      await _firestore.collection('sessions').doc(sessionId).update({
        'tutorRating': rating,
        'ratedAt': FieldValue.serverTimestamp(),
        'isRated': true,
      });

      // Show success message
      if (kDebugMode) {
        print('Rating submitted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting tutor rating: $e');
      }
      rethrow;
    }
  }

  // Get rating stream
  Stream<Map<String, dynamic>?> get ratingStream => _ratingSubject.stream;

  // Get tutor ratings with detailed information
  Future<Map<String, dynamic>> getTutorRatings(String tutorId) async {
    try {
      if (kDebugMode) {
        print('Fetching detailed ratings for tutor: $tutorId');
      }

      // Get all ratings for this tutor
      final QuerySnapshot ratingSnapshot = await _firestore
          .collection('ratings')
          .where('tutorId', isEqualTo: tutorId)
          .orderBy('timestamp', descending: true)
          .get();

      // Get tutor profile to get the aggregate rating info
      final tutorDoc = await _firestore.collection('users').doc(tutorId).get();
      final tutorData = tutorDoc.data() ?? {};

      // Get all unique students who have had sessions with this tutor
      final QuerySnapshot sessionSnapshot = await _firestore
          .collection('sessions')
          .where('recipientId', isEqualTo: tutorId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Count unique students
      final Set<String> uniqueStudents = {};
      for (final doc in sessionSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final requesterId = data['requesterId'] as String?;
        if (requesterId != null) {
          uniqueStudents.add(requesterId);
        }
      }

      // Extract detailed rating information
      final List<Map<String, dynamic>> detailedRatings =
          ratingSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'rating': data['rating'] ?? 0,
          'studentId': data['studentId'] ?? '',
          'sessionId': data['sessionId'] ?? '',
          'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
        };
      }).toList();

      // Get student names for each rating
      for (final rating in detailedRatings) {
        try {
          final studentId = rating['studentId'] as String;
          if (studentId.isNotEmpty) {
            final studentDoc =
                await _firestore.collection('users').doc(studentId).get();
            if (studentDoc.exists) {
              final studentData = studentDoc.data();
              rating['studentName'] =
                  studentData?['name'] ?? 'Anonymous Student';
            } else {
              rating['studentName'] = 'Anonymous Student';
            }
          } else {
            rating['studentName'] = 'Anonymous Student';
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching student info for rating: $e');
          }
          rating['studentName'] = 'Anonymous Student';
        }
      }

      return {
        'tutorId': tutorId,
        'averageRating': tutorData['averageRating'] ?? 0.0,
        'ratingCount': tutorData['ratingCount'] ?? 0,
        'sessionCount': sessionSnapshot.docs.length,
        'uniqueStudentCount': uniqueStudents.length,
        'detailedRatings': detailedRatings,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tutor ratings: $e');
      }
      return {
        'tutorId': tutorId,
        'averageRating': 0.0,
        'ratingCount': 0,
        'sessionCount': 0,
        'uniqueStudentCount': 0,
        'detailedRatings': <Map<String, dynamic>>[],
        'error': e.toString(),
      };
    }
  }

  // Format time as HH:MM:SS with leading zeros
  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }
}
