//lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/shared/settings_option.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SettingsOption(
            title: 'Change Password',
            onTap: () {
              // Navigate to change password screen
            },
          ),
          SettingsOption(
            title: 'Notifications',
            onTap: () {
              // Toggle notifications
            },
          ),
          SettingsOption(
            title: 'Logout',
            onTap: () async {
              // Handle logout
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/roleSelection');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}