//lib/screens/role_selection.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'login_screen.dart';
import '../utils/colors.dart';
import '../utils/styles.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 104, 26, 154), const Color.fromARGB(255, 125, 131, 72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
              children: [
                // Logo or Image
                Icon(Icons.school, size: 100, color: Colors.white)
                    .animate()
                    .fadeIn(duration: 1000.ms)
                    .scale(delay: 500.ms),
                SizedBox(height: 20),

                // Title
                Text("Select Your Role", style: AppStyles.heading1.copyWith(color: Colors.white))
                    .animate()
                    .fadeIn(duration: 1000.ms)
                    .slideY(duration: 500.ms),
                SizedBox(height: 30),

                // Buttons
                _buildRoleButton("Student", Icons.person, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(role: "student"), // Use lowercase for consistency
                    ),
                  );
                }).animate().slideX(duration: 500.ms, begin: -1),
                SizedBox(height: 20),

                _buildRoleButton("Tutor", Icons.school, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(role: "tutor"), // Use lowercase for consistency
                    ),
                  );
                }).animate().slideX(duration: 500.ms, begin: 1),
                SizedBox(height: 20),

                _buildRoleButton("Admin", Icons.admin_panel_settings, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(role: "admin"), // Use lowercase for consistency
                    ),
                  );
                }).animate().slideX(duration: 500.ms, begin: -1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.onPrimaryColor),
      label: Text(text, style: AppStyles.buttonText),
      style: ElevatedButton.styleFrom(
        // ignore: deprecated_member_use
        backgroundColor: AppColors.primaryColor.withOpacity(0.8),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        shadowColor: AppColors.secondaryColor,
      ),
    );
  }
}