//lib/screens/admin/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brainiacz/providers/auth_providers.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              try {
                await authProvider.fetchUsers(); // Refresh the user list
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User list refreshed!')),
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to refresh users: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: authProvider.fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load users. Please try again.'),
            );
          }

          if (authProvider.users.isEmpty) {
            return Center(
              child: Text('No users found.'),
            );
          }

          return ListView.builder(
            itemCount: authProvider.users.length,
            itemBuilder: (context, index) {
              final user = authProvider.users[index];
              final userStatus = user['status'] ?? 'pending'; // Default status

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(user['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? 'No Email'),
                      SizedBox(height: 4),
                      Text(
                        'Status: ${userStatus.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(userStatus),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Approve User Button (only show if status is not approved)
                      if (userStatus != 'approved')
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await _confirmAction(
                              context,
                              title: 'Approve User',
                              message: 'Are you sure you want to approve this user?',
                              onConfirm: () async {
                                try {
                                  await authProvider.approveUser(user['id']);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('User approved successfully!')),
                                  );
                                } catch (e) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to approve user: $e')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      // Suspend User Button (only show if status is not suspended)
                      if (userStatus != 'suspended')
                        IconButton(
                          icon: Icon(Icons.pause, color: Colors.orange),
                          onPressed: () async {
                            await _confirmAction(
                              context,
                              title: 'Suspend User',
                              message: 'Are you sure you want to suspend this user?',
                              onConfirm: () async {
                                try {
                                  await authProvider.suspendUser(user['id']);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('User suspended successfully!')),
                                  );
                                } catch (e) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to suspend user: $e')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      // Remove User Button
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _confirmAction(
                            context,
                            title: 'Remove User',
                            message: 'Are you sure you want to remove this user?',
                            onConfirm: () async {
                              try {
                                await authProvider.removeUser(user['id']);
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('User removed successfully!')),
                                );
                              } catch (e) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to remove user: $e')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to show a confirmation dialog
  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}