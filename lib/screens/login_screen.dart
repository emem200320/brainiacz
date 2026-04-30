// lib/screens/login_screen.dart
import 'package:brainiacz/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/styles.dart';
import '../widgets/custom_button.dart';

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Account Banned', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.block, color: Colors.red, size: 50),
                SizedBox(height: 16),
                Text(
                  'This account has been banned due to violations of our terms of service.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
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

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Login as ${widget.role[0].toUpperCase()}${widget.role.substring(1)}',
          style: AppStyles.heading1.copyWith(fontSize: 20),
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
              Image.asset(
                'assets/brainiacz logo.png',
                height: 160,
              ),
              const SizedBox(height: 40),

              // ── Welcome text ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Welcome back!', style: AppStyles.heading1),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sign in to continue',
                  style: AppStyles.bodyText.copyWith(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),

              // ── Email Field ──
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // ── Password Field ──
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[500],
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              // ── Forgot Password ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: implement forgot password
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppStyles.bodyText.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Login Button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: 'Login',
                        onPressed: () => _handleLogin(authProvider),
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
                      style: AppStyles.bodyText.copyWith(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                      child: Text(
                        'Sign Up',
                        style: AppStyles.bodyText.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryColor,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyText.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppStyles.bodyText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyText.copyWith(color: Colors.grey[400]),
            filled: true,
            fillColor: AppColors.backgroundColor,
            prefixIcon: Icon(prefixIcon, color: AppColors.primaryColor, size: 22),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }
}