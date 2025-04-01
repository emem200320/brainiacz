// lib/widgets/role_guard.dart
import 'package:brainiacz/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleGuard({super.key, required this.child, required this.allowedRoles, required bool debugShowCheckedModeBanner});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) {
      // Redirect to login screen if the user is not logged in
      // ignore: use_build_context_synchronously
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!allowedRoles.contains(authProvider.userRole)) {
      // Redirect to splash screen if the user's role is not allowed
      Future.microtask(() {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/splash');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unauthorized access. Please log in with the correct role.')),
        );
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If the user is logged in and has the correct role, render the child widget
    return child;
  }
}