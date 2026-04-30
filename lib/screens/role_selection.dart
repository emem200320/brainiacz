// lib/screens/role_selection.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // ── Icon ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C3FD8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 38),
              )
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .scale(delay: 200.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              // ── Title ──
              const Text(
                'Select Your Role',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 200.ms)
                  .slideY(begin: 0.2, duration: 500.ms),

              const SizedBox(height: 6),

              const Text(
                'Choose how you want to continue',
                style: TextStyle(
                  color: Color(0xFF888899),
                  fontSize: 14,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 300.ms),

              const SizedBox(height: 48),

              // ── Buttons ──
              _buildRoleButton(
                label: 'Student',
                subtitle: 'Find & book tutors',
                icon: Icons.person_rounded,
                isPrimary: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen(role: 'student')),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideX(begin: -0.2, duration: 500.ms),

              const SizedBox(height: 14),

              _buildRoleButton(
                label: 'Tutor',
                subtitle: 'Teach & earn',
                icon: Icons.menu_book_rounded,
                isPrimary: false,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen(role: 'tutor')),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideX(begin: 0.2, duration: 500.ms),

              const SizedBox(height: 14),

              _buildRoleButton(
                label: 'Admin',
                subtitle: 'Manage platform',
                icon: Icons.admin_panel_settings_rounded,
                isPrimary: false,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen(role: 'admin')),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideX(begin: -0.2, duration: 500.ms),

              const Spacer(),

              // ── Footer ──
              const Text(
                'BRAINIACZ',
                style: TextStyle(
                  color: Color(0xFF333344),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 800.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF6C3FD8) : const Color(0xFF13131F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.transparent : const Color(0xFF6C3FD8),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFF6C3FD8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFFA78BFA),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isPrimary
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF888899),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isPrimary ? Colors.white.withOpacity(0.7) : const Color(0xFF444455),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}