// lib/models/student.dart
import 'user.dart';

class Student extends User {
  final List<String> subjectsOfInterest;

  Student({
    required super.id,
    required super.name,
    required super.email,
    required this.subjectsOfInterest,
    super.profileImageUrl,
  }) : super(
          role: 'student',
        );

  factory Student.fromMap(Map<String, dynamic> data) {
    return Student(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      subjectsOfInterest: List<String>.from(data['subjectsOfInterest']),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subjectsOfInterest': subjectsOfInterest,
      'profileImageUrl': profileImageUrl,
    };
  }
}