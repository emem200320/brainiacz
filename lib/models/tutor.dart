//lib/models/tutor.dart
import 'user.dart';

class Tutor extends User {
  final List<String> subjects;
  final String bio;
  final double rating;
  final bool isAvailable;
  final String phone;
  final String? specialtySubject;

  Tutor({
    required super.id,
    required super.name,
    required super.email,
    required this.subjects,
    required this.bio,
    required this.phone,
    this.specialtySubject,
    this.rating = 0.0,
    this.isAvailable = true,
    super.profileImageUrl,
  }) : super(
          role: 'tutor',
        );

  factory Tutor.fromMap(Map<String, dynamic> data) {
    // Get the rating, checking multiple possible fields
    double rating = 0.0;
    if (data.containsKey('averageRating') && data['averageRating'] != null) {
      rating = (data['averageRating'] as num).toDouble();
    } else if (data.containsKey('rating') && data['rating'] != null) {
      rating = (data['rating'] as num).toDouble();
    }
    
    return Tutor(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      subjects: List<String>.from(data['subjects']),
      bio: data['bio'],
      phone: data['phone'] ?? 'Not available',
      specialtySubject: data['specialtySubject'],
      rating: rating,
      isAvailable: data['isAvailable'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subjects': subjects,
      'bio': bio,
      'phone': phone,
      'specialtySubject': specialtySubject,
      'rating': rating,
      'isAvailable': isAvailable,
      'profileImageUrl': profileImageUrl,
    };
  }
}