// lib/widgets/shared/profile_form.dart
import 'package:flutter/material.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  ProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _bioController,
          decoration: InputDecoration(labelText: 'Bio'),
          maxLines: 3,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Save profile changes
            final name = _nameController.text.trim();
            final bio = _bioController.text.trim();
            if (name.isNotEmpty && bio.isNotEmpty) {
              // Save logic (e.g., update Firestore)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile updated successfully!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please fill all fields')),
              );
            }
          },
          child: Text('Save Changes'),
        ),
      ],
    );
  }
}