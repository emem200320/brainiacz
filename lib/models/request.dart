//lib/models/request.dart
class Request {
  final String id;
  final String studentId;
  final String tutorId;
  final String subjectId;
  final DateTime requestedAt;
  final DateTime sessionDate; // New field
  final String sessionTime; // New field
  final String status; // 'pending', 'accepted', 'rejected'

  Request({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.subjectId,
    required this.requestedAt,
    required this.sessionDate, // New field
    required this.sessionTime, // New field
    this.status = 'pending',
  });

  // fromMap method
  factory Request.fromMap(Map<String, dynamic> data) {
    return Request(
      id: data['id'],
      studentId: data['studentId'],
      tutorId: data['tutorId'],
      subjectId: data['subjectId'],
      requestedAt: DateTime.parse(data['requestedAt']),
      sessionDate: DateTime.parse(data['sessionDate']), // Parse sessionDate
      sessionTime: data['sessionTime'], // Add sessionTime
      status: data['status'],
    );
  }

  // toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'tutorId': tutorId,
      'subjectId': subjectId,
      'requestedAt': requestedAt.toIso8601String(),
      'sessionDate': sessionDate.toIso8601String(), // Add sessionDate
      'sessionTime': sessionTime, // Add sessionTime
      'status': status,
    };
  }
}