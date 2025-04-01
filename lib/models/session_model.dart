// lib/models/session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus {
  requested,
  active,
  paused,
  completed,
  cancelled,
}

class SessionModel {
  final String id;
  final String requesterId;
  final String recipientId;
  final int durationMinutes;
  final DateTime requestTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final int elapsedSeconds;
  final bool requesterPaused;
  final bool recipientPaused;
  
  const SessionModel({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.durationMinutes,
    required this.requestTime,
    this.startTime,
    this.endTime,
    required this.status,
    this.elapsedSeconds = 0,
    this.requesterPaused = false,
    this.recipientPaused = false,
  });
  
  // Parse a SessionStatus from a string value
  static SessionStatus _parseStatus(String status) {
    return SessionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => SessionStatus.requested,
    );
  }
  
  // Create a SessionModel from a Firestore Map
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String?;
    SessionStatus sessionStatus = SessionStatus.requested;
    
    if (statusStr != null) {
      sessionStatus = _parseStatus(statusStr);
    }
    
    // Parse timestamps
    Timestamp? startTimestamp = map['startTime'] as Timestamp?;
    Timestamp? endTimestamp = map['endTime'] as Timestamp?;
    Timestamp requestTimestamp = map['requestTime'] as Timestamp? ?? 
        Timestamp.fromDate(DateTime.now());
    
    return SessionModel(
      id: map['id'] as String,
      requesterId: map['requesterId'] as String,
      recipientId: map['recipientId'] as String,
      durationMinutes: map['durationMinutes'] as int,
      requestTime: requestTimestamp.toDate(),
      startTime: startTimestamp?.toDate(),
      endTime: endTimestamp?.toDate(),
      status: sessionStatus,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      requesterPaused: map['requesterPaused'] as bool? ?? false,
      recipientPaused: map['recipientPaused'] as bool? ?? false,
    );
  }
  
  // Convert SessionModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'recipientId': recipientId,
      'durationMinutes': durationMinutes,
      'requestTime': Timestamp.fromDate(requestTime),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.toString().split('.').last,
      'elapsedSeconds': elapsedSeconds,
      'requesterPaused': requesterPaused,
      'recipientPaused': recipientPaused,
      'participants': [requesterId, recipientId],
    };
  }
  
  // Get remaining time in session, accounting for elapsed time 
  Duration get remainingTime {
    if (status == SessionStatus.completed || 
        status == SessionStatus.cancelled ||
        startTime == null) {
      return Duration.zero;
    }
    
    // If the session is requested but not yet active, return the full duration
    if (status == SessionStatus.requested) {
      return Duration(minutes: durationMinutes);
    }
    
    final totalDuration = Duration(minutes: durationMinutes);
    
    // Calculate elapsed time, considering both stored elapsed seconds and
    // any additional time that has passed since last update if not paused
    int totalElapsedSeconds = elapsedSeconds;
    
    // Only count additional elapsed time if session is active and not paused
    if (!isPaused && status == SessionStatus.active) {
      final now = DateTime.now();
      final additionalSeconds = now.difference(startTime!).inSeconds - elapsedSeconds;
      // Only add if it's a positive value (to handle any edge cases)
      if (additionalSeconds > 0) {
        totalElapsedSeconds += additionalSeconds;
      }
    }
    
    final elapsed = Duration(seconds: totalElapsedSeconds);
    final remaining = totalDuration - elapsed;
    
    // Ensure we never return negative duration
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  // Check if the session is paused (either both users paused or status is paused)
  bool get isPaused {
    return status == SessionStatus.paused || (requesterPaused || recipientPaused);
  }
  
  // Clone this SessionModel with some new values
  SessionModel copyWith({
    String? id,
    String? requesterId,
    String? recipientId,
    int? durationMinutes,
    DateTime? requestTime,
    DateTime? startTime,
    DateTime? endTime,
    SessionStatus? status,
    int? elapsedSeconds,
    bool? requesterPaused,
    bool? recipientPaused,
  }) {
    return SessionModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      recipientId: recipientId ?? this.recipientId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      requestTime: requestTime ?? this.requestTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      requesterPaused: requesterPaused ?? this.requesterPaused,
      recipientPaused: recipientPaused ?? this.recipientPaused,
    );
  }
  
  // Check if a user is paused
  bool isUserPaused(String userId) {
    if (userId == requesterId) {
      return requesterPaused;
    } else if (userId == recipientId) {
      return recipientPaused;
    }
    return false;
  }
  
  // Format session duration
  String get formattedDuration {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return '$durationMinutes ${durationMinutes == 1 ? 'minute' : 'minutes'}';
    }
  }
  
  List<String> get participants => [requesterId, recipientId];
}
