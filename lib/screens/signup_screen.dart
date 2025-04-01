//lib/screens/signup_screen.dart
import 'package:brainiacz/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class SignupScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'student';

  SignupScreen({super.key}); // Default role

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['student', 'tutor']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                _selectedRole = value!;
              },
              decoration: InputDecoration(labelText: 'Select Role'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await authProvider.signup(
                    name: name,
                    email: email,
                    password: password,
                    role: _selectedRole,
                  );
                  // Navigate to the appropriate home screen
                  if (_selectedRole == 'student') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/studentHome');
                  } else if (_selectedRole == 'tutor') {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/tutorHome');
                  }
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signup failed: $e')),
                  );
                }
              },
              child: Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}