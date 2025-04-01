// lib/models/admin.dart
import 'user.dart';

class Admin extends User {
  Admin({
    required super.id,
    required super.name,
    required super.email,
    super.profileImageUrl,
  }) : super(
          role: 'admin',
        );

  factory Admin.fromMap(Map<String, dynamic> data) {
    return Admin(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }
}