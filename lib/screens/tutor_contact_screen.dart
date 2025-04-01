// lib/screens/tutor_contact_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tutor_provider.dart';

class TutorContactScreen extends StatelessWidget {
  const TutorContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorProvider = Provider.of<TutorProvider>(context);
    final tutor = tutorProvider.selectedTutor;

    if (tutor == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Tutor Contact Info')),
        body: Center(child: Text('No tutor selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Tutor Contact Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${tutor['name']}', style: TextStyle(fontSize: 18)),
            Text('Email: ${tutor['email']}', style: TextStyle(fontSize: 16)),
            Text('Phone: ${tutor['phone'] ?? 'Not provided'}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}