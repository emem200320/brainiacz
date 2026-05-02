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
        backgroundColor: const Color(0xFF13131F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ban User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ban $userName?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('This will prevent the user from logging in.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _banReasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Ban Reason',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'Provide a reason',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF0A0A0F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF6C3FD8).withOpacity(0.25))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3FD8), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Confirm Ban'),
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
          backgroundColor: const Color(0xFF13131F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('User Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(Icons.person_rounded, 'Name', userData['name'] ?? userData['fullName'] ?? userData['displayName'] ?? userName),
                _detailRow(Icons.email_rounded, 'Email', userData['email'] ?? 'Not provided'),
                _detailRow(Icons.badge_rounded, 'Role', userData['role'] ?? 'Unknown'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFA78BFA))),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Reported Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C3FD8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF6C3FD8),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA78BFA), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
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
                const Icon(Icons.check_circle_rounded, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No reported ${role}s',
                  style: const TextStyle(fontSize: 16, color: Colors.white38),
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

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: needsAction
                      ? Colors.redAccent.withOpacity(0.4)
                      : const Color(0xFF6C3FD8).withOpacity(0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: needsAction
                              ? Colors.redAccent.withOpacity(0.2)
                              : const Color(0xFF6C3FD8).withOpacity(0.2),
                          child: Text(
                            userName[0],
                            style: TextStyle(
                              color: needsAction ? Colors.redAccent : const Color(0xFFA78BFA),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                              Text(
                                '$reportCount ${reportCount == 1 ? 'report' : 'reports'}',
                                style: TextStyle(
                                  color: needsAction ? Colors.redAccent : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: needsAction ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (needsAction)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Action Required', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: const Color(0xFF6C3FD8).withOpacity(0.15), height: 1),
                    const SizedBox(height: 12),
                    const Text('Recent Reports:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...reports.take(3).map((report) {
                      final data = report.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Color(0xFFA78BFA))),
                            Expanded(child: Text(data['reason'] ?? 'No reason provided', style: const TextStyle(color: Colors.white54, fontSize: 13))),
                          ],
                        ),
                      );
                    }),
                    if (reports.length > 3)
                      Text('... and ${reports.length - 3} more', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _viewUserDetails(userId, userName, role),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFA78BFA),
                            side: const BorderSide(color: Color(0xFF6C3FD8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text('View Details'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: needsAction ? () => _banUser(userId, userName) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: needsAction ? Colors.redAccent : Colors.white12,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            elevation: 0,
                          ),
                          child: const Text('Ban User'),
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