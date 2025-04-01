// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student', 'tutor', or 'admin'
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      role: data['role'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
    };
  }
}