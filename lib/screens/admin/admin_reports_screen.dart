//lib/screens/admin/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _banUser(String userId, String userName) async {
    // Show a dialog to confirm and provide ban reason
    TextEditingController _banReasonController = TextEditingController();
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ban User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ban $userName?'),
            SizedBox(height: 12),
            Text('This will prevent the user from logging in and using the platform.'),
            SizedBox(height: 16),
            TextField(
              controller: _banReasonController,
              decoration: InputDecoration(
                labelText: 'Ban Reason',
                hintText: 'Provide a reason for banning this user',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm Ban'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    String banReason = _banReasonController.text.trim();
    if (banReason.isEmpty) {
      banReason = "Banned by administrator due to multiple reports";
    }

    try {
      // Create a batch to ensure all operations complete together
      WriteBatch batch = _firestore.batch();
      
      // Update the user document to mark them as banned
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'isBanned': true,
        'banReason': banReason,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      });
      
      // Resolve all reports for this user
      QuerySnapshot reports = await _firestore
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();
      
      for (var doc in reports.docs) {
        batch.update(doc.reference, {
          'status': 'resolved',
          'resolution': 'User banned',
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        });
      }
      
      await batch.commit();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName has been banned and can no longer log in'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Refresh the reports list
      setState(() {});
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error banning user: $e')),
      );
    }
  }

  Future<void> _viewUserDetails(String userId, String userName, String role) async {
    setState(() {
    });

    try {
      // Fetch the user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found')),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: Text('User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User basic info
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Name'),
                  subtitle: Text(userData['name'] ?? userData['fullName'] ?? userData['displayName'] ?? userName),
                ),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text(userData['email'] ?? 'Not provided'),
                ),
                ListTile(
                  leading: Icon(Icons.badge),
                  title: Text('Role'),
                  subtitle: Text(userData['role'] ?? 'Unknown'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user details: $e')),
      );
    } finally {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reported Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Students'),
            Tab(text: 'Tutors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Reported Students Tab
          _buildReportedUsersList('student'),
          
          // Reported Tutors Tab
          _buildReportedUsersList('tutor'),
        ],
      ),
    );
  }

  Widget _buildReportedUsersList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reports')
          .where('reportedUserRole', isEqualTo: role)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No reported ${role}s',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        // Group reports by reported user ID
        final reportsByUser = <String, List<DocumentSnapshot>>{};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final reportedUserId = data['reportedUserId'] as String;
          
          if (!reportsByUser.containsKey(reportedUserId)) {
            reportsByUser[reportedUserId] = [];
          }
          reportsByUser[reportedUserId]!.add(doc);
        }

        return ListView.builder(
          itemCount: reportsByUser.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final userId = reportsByUser.keys.elementAt(index);
            final reports = reportsByUser[userId]!;
            final reportCount = reports.length;
            final firstReport = reports.first.data() as Map<String, dynamic>;
            final userName = firstReport['reportedUserName'] ?? 'Unknown User';
            final needsAction = reportCount >= 5;

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: needsAction ? Colors.red : Colors.blue,
                          child: Text(userName[0]),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '$reportCount ${reportCount == 1 ? 'report' : 'reports'}',
                                style: TextStyle(
                                  color: needsAction ? Colors.red : Colors.grey,
                                  fontWeight: needsAction ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (needsAction)
                          Chip(
                            label: Text('Action Required'),
                            backgroundColor: Colors.red[100],
                            labelStyle: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Recent Reports:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ...reports.take(3).map((report) {
                      final data = report.data() as Map<String, dynamic>;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('• ${data['reason'] ?? 'No reason provided'}'),
                      );
                    }),
                    if (reports.length > 3)
                      Text('... and ${reports.length - 3} more'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _viewUserDetails(userId, userName, role);
                          },
                          child: Text('View Details'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: needsAction
                              ? () => _banUser(userId, userName)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: needsAction ? Colors.red : Colors.grey,
                          ),
                          child: Text('Ban User'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}