// lib/models/subject.dart
class Subject {
  final String id;
  final String name;
  final String description;

  Subject({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Subject.fromMap(Map<String, dynamic> data) {
    return Subject(
      id: data['id'],
      name: data['name'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}