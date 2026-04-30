// lib/widgets/shared/profile_form.dart
import 'package:flutter/material.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  ProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name Field ──
        _buildLabel('Name'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _nameController,
          hint: 'Enter your name',
          prefixIcon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 20),

        // ── Bio Field ──
        _buildLabel('Bio'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _bioController,
          hint: 'Tell us about yourself...',
          prefixIcon: Icons.edit_note_rounded,
          maxLines: 4,
        ),

        const SizedBox(height: 32),

        // ── Save Button ──
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C3FD8).withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final bio = _bioController.text.trim();
              if (name.isNotEmpty && bio.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Color(0xFF6C3FD8),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3FD8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFF13131F),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
          child: Icon(prefixIcon, color: const Color(0xFF6C3FD8), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6C3FD8).withOpacity(0.25),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6C3FD8).withOpacity(0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF6C3FD8),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
    );
  }
}