//lib/screens/login_screen.dart
import 'package:brainiacz/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LoginScreen extends StatelessWidget {
  final String role;
  LoginScreen({super.key, required this.role});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Login as $role')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await authProvider.login(
                    email: email,
                    password: password,
                    role: role,
                  );
                  // Navigate to the appropriate home screen
                  if (role == 'student') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/studentHome');
                  } else if (role == 'tutor') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/tutorHome');
                  } else if (role == 'admin') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/adminHome');
                  }
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  
                  // Check for banned account message and show a more prominent alert
                  if (e.toString().contains('account has been banned')) {
                    // ignore: use_build_context_synchronously
                    showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: Text('Account Banned', style: TextStyle(color: Colors.red)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, color: Colors.red, size: 50),
                            SizedBox(height: 16),
                            Text(
                              'This account has been banned due to violations of our terms of service.',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Regular error message for other login failures
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $e')),
                    );
                  }
                }
              },
              child: Text('Login'),
            ),
            // Hide "Sign Up" button for admin
            if (role != 'admin') // Only show for non-admin roles
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: Text('Don’t have an account? Sign Up'),
              ),
          ],
        ),
      ),
    );
  }
}