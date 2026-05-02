//lib/screens/signup_screen.dart
import 'package:brainiacz/providers/auth_providers.dart';
import 'package:brainiacz/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: const Color(0xFF6C3FD8), size: 20),
      filled: true,
      fillColor: const Color(0xFF13131F),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Header
            const Text(
              'Create Account',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Join Brainiacz and start learning',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 36),

            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration('Full Name', Icons.person_rounded),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration('Email', Icons.email_rounded),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: _obscurePassword,
              decoration: _fieldDecoration('Password', Icons.lock_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  dropdownColor: const Color(0xFF13131F),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6C3FD8)),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  items: [
                    DropdownMenuItem(
                      value: 'student',
                      child: Row(children: const [
                        Icon(Icons.school_rounded, color: Color(0xFFA78BFA), size: 18),
                        SizedBox(width: 10),
                        Text('Student'),
                      ]),
                    ),
                    DropdownMenuItem(
                      value: 'tutor',
                      child: Row(children: const [
                        Icon(Icons.cast_for_education_rounded, color: Color(0xFFA78BFA), size: 18),
                        SizedBox(width: 10),
                        Text('Tutor'),
                      ]),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Sign Up button
            GestureDetector(
              onTap: _isLoading ? null : () async {
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please fill all fields'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);
                try {
                  await authProvider.signup(
                    name: name,
                    email: email,
                    password: password,
                    role: _selectedRole,
                  );
                  if (_selectedRole == 'student') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/studentHome');
                  } else if (_selectedRole == 'tutor') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/tutorHome');
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Signup failed: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C3FD8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C3FD8).withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login link
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(role: _selectedRole),
                ),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}