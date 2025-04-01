//lib/screens/tutor_sessions_screen.dart
import 'package:flutter/material.dart';

class TutorSessionsScreen extends StatelessWidget {
  const TutorSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Session Requests')),
      body: ListView.builder(
        itemCount: 10, // Replace with Firestore data
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text('Request from Student $index'),
              subtitle: Text('Subject: Math | Date: 2023-10-15'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      // Accept session request
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      // Reject session request
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}