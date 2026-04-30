// lib/screens/login_screen.dart
import 'package:brainiacz/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authProvider.login(
        email: email,
        password: password,
        role: widget.role,
      );

      if (!mounted) return;

      if (widget.role == 'student') {
        Navigator.pushReplacementNamed(context, '/studentHome');
      } else if (widget.role == 'tutor') {
        Navigator.pushReplacementNamed(context, '/tutorHome');
      } else if (widget.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminHome');
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('account has been banned')) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF13131F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Account Banned', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.block, color: Colors.red, size: 50),
                SizedBox(height: 16),
                Text(
                  'This account has been banned due to violations of our terms of service.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Color(0xFF6C3FD8))),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final roleLabel = widget.role[0].toUpperCase() + widget.role.substring(1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Login as $roleLabel',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Logo ──
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/brainiacz logo.png',
                  height: 140,
                ),
              ),

              const SizedBox(height: 36),

              // ── Welcome Text ──
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sign in to continue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Email Field ──
              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'Enter your email',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // ── Password Field ──
              _buildLabel('Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 32),

              // ── Login Button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C3FD8),
                        ),
                      )
                    : Container(
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
                        onPressed: () => _handleLogin(authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3FD8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      ),
              ),

              const SizedBox(height: 24),

              // ── Sign Up Link ──
              if (widget.role != 'admin')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFA78BFA),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFF13131F),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6C3FD8), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF6C3FD8).withOpacity(0.25), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}