//lib/screens/shared/profile_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/shared/profile_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ProfileForm(),
      ),
    );
  }
}