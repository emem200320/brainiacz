// lib/screens/shared/profile_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/shared/profile_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar placeholder ──
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF13131F),
                        border: Border.all(
                          color: const Color(0xFF6C3FD8).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF6C3FD8),
                        size: 44,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C3FD8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A0A0F),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ProfileForm(),
            ],
          ),
        ),
      ),
    );
  }
}