//lib/screens/admin_content_moderation_screen.dart
import 'package:flutter/material.dart';

class AdminContentModerationScreen extends StatelessWidget {
  const AdminContentModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Content Moderation')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Reported Message 1'),
            subtitle: Text('From: John Doe'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Handle delete
              },
            ),
          ),
          ListTile(
            title: Text('Reported Review 1'),
            subtitle: Text('From: Jane Smith'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Handle delete
              },
            ),
          ),
        ],
      ),
    );
  }
}