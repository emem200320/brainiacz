//lib/screens/admin_home_screen.dart
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C3FD8).withOpacity(0.1),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C3FD8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C3FD8).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      Text('Admin', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Quick Actions',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            _adminCard(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'View Reports',
              subtitle: 'Analytics & data',
              onTap: () => Navigator.pushNamed(context, '/adminReports'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF6C3FD8).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFA78BFA), size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}