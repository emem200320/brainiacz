//lib/screens/tutor/tutor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../chat_screen.dart';
import '../tutor_profile_screen.dart';
import '../student_profile_screen.dart';
import 'package:brainiacz/screens/tutor/tutor_modules_screen.dart';

class TutorHomeScreen extends StatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<QueryDocumentSnapshot<Object?>>? _requests;
  List<QueryDocumentSnapshot<Object?>>? _chats;
  DateTime _lastRequestsRefresh = DateTime.now();
  DateTime _lastChatsRefresh = DateTime.now();

  // Tab controller for different sections
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Change length from 3 to 4 tabs
    _tabController = TabController(length: 4, vsync: this);
    _tabController.index = 0;

    // Load initial data
    _loadRequests();
    _loadChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load requests data manually
  Future<void> _loadRequests() async {
    if (kDebugMode) {
      print('Loading tutor requests data manually');
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _isLoading = false;
        _requests = []; // Initialize with empty list if no user
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      if (kDebugMode) {
        print('Fetching requests for tutor ID: $currentUserId');
      }

      // Use get() instead of snapshots() for manual refresh
      final snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('tutorId', isEqualTo: currentUserId)
          .get();

      if (kDebugMode) {
        print('Loaded ${snapshot.docs.length} tutor requests');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print(
              'Request: ${doc.id} - status: ${data['status']} - student: ${data['studentId']}');
        }
      }

      setState(() {
        _requests = snapshot.docs;
        _lastRequestsRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tutor requests: $e');
      }

      setState(() {
        _isLoading = false;
        _requests = []; // Initialize with empty list on error
      });

      // Show error to user
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load requests: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Load chats data
  Future<void> _loadChats() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _isLoading = false;
        _chats = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Simple query to get all chats where current user is a participant
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Sort chats by timestamp (newest first)
      final sortedDocs = snapshot.docs;
      sortedDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();

        final aTimestamp =
            aData['updatedAt'] ?? aData['lastTimestamp'] ?? aData['createdAt'];
        final bTimestamp =
            bData['updatedAt'] ?? bData['lastTimestamp'] ?? bData['createdAt'];

        if (aTimestamp == null || bTimestamp == null) return 0;

        if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
          return bTimestamp.compareTo(aTimestamp); // Newest first
        }

        return 0;
      });

      setState(() {
        _chats = sortedDocs;
        _lastChatsRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chats = [];
      });

      // Show error to user
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Refresh all data at once
  Future<void> _refreshAll() async {
    await _loadRequests();
    await _loadChats();
  }

  // Format relative time display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _acceptRequest(String requestId, String studentId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Get request details first to access subject information
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .get();

      final requestData = requestDoc.data();
      final subject = requestData?['subject'] ?? 'General tutoring';

      // 2. Update request status to accepted
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Get user data for chat creation
      final tutorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();

      final tutorData = tutorDoc.data();
      final studentData = studentDoc.data();

      final tutorName = tutorData?['name'] ?? tutorData?['fullName'] ?? 'Tutor';
      final studentName =
          studentData?['name'] ?? studentData?['fullName'] ?? 'Student';

      // 4. Create chat ID using the getChatId pattern used in ChatScreen
      String chatId = _getChatId(currentUserId, studentId);

      // 5. Check if chat already exists to prevent duplicates
      final existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!existingChat.exists) {
        // Generate a meaningful initial message based on the subject
        final initialMessage = 'Tutoring session for $subject';

        // Create new chat only if it doesn't exist with fields matching ChatScreen expectations
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'participants': [currentUserId, studentId],
          'participantNames': [tutorName, studentName],
          'lastMessage': initialMessage,
          'subject': subject, // Store the subject for reference
          'lastTimestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add initial system message with meaningful context
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': 'system',
          'senderName': 'System',
          'receiverId': 'both',
          'content':
              'Tutoring session for $subject has been started. You can now begin chatting!',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'imageUrl': null,
          'linkUrl': null,
        });
      }

      // 6. Refresh both request and chat lists
      if (mounted) {
        await _loadRequests();
        await _loadChats();

        setState(() {
          _isLoading = false;
        });

        // Show success message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted! Chat created with student.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to create consistent chat IDs matching ChatScreen
  String _getChatId(String uid1, String uid2) {
    List<String> sortedIds = [uid1, uid2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Helper method to show student profile
  void _showStudentProfile(String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileScreen(studentId: studentId),
      ),
    );
  }

  Widget _buildRequestsList() {
    // Initialize _requests to empty list if null to prevent loading issues
    if (_requests == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No requests loaded'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadRequests,
              child: Text('Load Requests'),
            ),
          ],
        ),
      );
    }

    if (_requests!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No pending requests',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRequests,
                icon: Icon(Icons.refresh),
                label: Text('Check Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Count pending requests
    final pendingRequests = _requests!.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'pending';
    }).toList();

    if (pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              SizedBox(height: 8),
              Text('All requests have been processed',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRequests,
                icon: Icon(Icons.refresh),
                label: Text('Check Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _requests!.length,
      itemBuilder: (context, index) {
        final request = _requests![index];
        final requestData = request.data() as Map<String, dynamic>;
        final requestId = request.id;
        final status = requestData['status'] ?? 'pending';

        // Don't skip any requests anymore - show all requests regardless of status
        // for debugging purposes

        final studentId = requestData['studentId'];
        final subject = requestData['subject'];

        // Safely handle the sessionDate field with proper type checking
        String formattedSessionDate = 'Not specified';
        if (requestData['sessionDate'] != null) {
          try {
            if (requestData['sessionDate'] is Timestamp) {
              // If it's already a Timestamp, process it correctly
              formattedSessionDate = DateFormat('MMM d, yyyy')
                  .format((requestData['sessionDate'] as Timestamp).toDate());
            } else if (requestData['sessionDate'] is String) {
              // If it's a String, try to parse it as a date
              formattedSessionDate = requestData['sessionDate'];
            } else {
              // For any other type, use default message
              formattedSessionDate = 'Invalid date format';
              if (kDebugMode) {
                print(
                    'Unknown sessionDate type: ${requestData['sessionDate'].runtimeType}');
              }
            }
          } catch (e) {
            // Handle any errors during date formatting
            formattedSessionDate = 'Error parsing date';
            if (kDebugMode) {
              print('Error formatting sessionDate: $e');
            }
          }
        }

        final sessionTime = requestData['sessionTime'] ?? 'Not specified';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get(),
          builder: (context, snapshot) {
            String studentName = 'Loading...';
            String? studentProfileUrl;

            if (snapshot.hasData && snapshot.data != null) {
              final studentData =
                  snapshot.data!.data() as Map<String, dynamic>?;
              studentName = studentData?['name'] ?? 'Unknown Student';
              studentProfileUrl = studentData?['profileImageUrl'];
            }

            // Different UI based on status
            Color cardColor;
            Widget actionButtons;

            switch (status) {
              case 'accepted':
                cardColor = const Color(0xFF0D1F14);
                actionButtons = Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF6C3FD8)),
                      label: const Text('Open Chat', style: TextStyle(color: Color(0xFF6C3FD8))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6C3FD8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              recipientId: studentId,
                              recipientName: studentName,
                            ),
                          ),
                        ).then((_) {
                          // Refresh chat list when returning from chat screen
                          _loadChats();
                        });
                      },
                    ),
                  ],
                );
                break;
              case 'rejected':
                cardColor = const Color(0xFF1F0D0D);
                actionButtons = Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Request declined',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white30)),
                );
                break;
              case 'pending':
              default:
                cardColor = const Color(0xFF13131F);
                actionButtons = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showStudentProfile(studentId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA78BFA),
                        side: const BorderSide(color: Color(0xFF6C3FD8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('View Profile', style: TextStyle(fontSize: 13)),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('requests')
                            .doc(requestId)
                            .update({
                          'status': 'rejected',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        _loadRequests();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Decline', style: TextStyle(fontSize: 13)),
                    ),
                    ElevatedButton(
                      onPressed: () async => await _acceptRequest(requestId, studentId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3FD8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                );
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: status == 'accepted'
                      ? Colors.green.withOpacity(0.3)
                      : status == 'rejected'
                          ? Colors.red.withOpacity(0.3)
                          : const Color(0xFF6C3FD8).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF6C3FD8).withOpacity(0.2),
                          backgroundImage: studentProfileUrl != null
                              ? NetworkImage(studentProfileUrl)
                              : null,
                          child: studentProfileUrl == null
                              ? Text(
                                  studentName.isNotEmpty ? studentName[0] : '?',
                                  style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              Text(
                                '$subject · $formattedSessionDate at $sessionTime',
                                style: const TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                              const SizedBox(height: 2),
                              Text('Status: $status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: status == 'accepted'
                                        ? Colors.greenAccent
                                        : status == 'rejected'
                                            ? Colors.redAccent
                                            : const Color(0xFFA78BFA),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    actionButtons,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveChatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Chats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            Row(
              children: [
                Text('Last updated: ${_formatTime(_lastChatsRefresh)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white30)),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C3FD8)),
                  onPressed: () {
                    if (kDebugMode) {
                      print("Manual refresh of tutor chats requested");
                    }
                    // Refresh using setState instead of navigation
                    _loadChats();
                  },
                  tooltip: 'Refresh chats',
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildChatsList(),
      ],
    );
  }

  Widget _buildChatsList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return SizedBox.shrink();

    // Initialize _chats to empty list if null to prevent loading issues
    if (_chats == null) {
      _chats = [];
      return Center(child: Text('No chats found. Tap refresh to try again.'));
    }

    if (_chats!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.blue),
              SizedBox(height: 8),
              Text('No active chats',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('Accept student requests to start chatting',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (kDebugMode) {
      print('Building chat list with ${_chats!.length} chats');
    }

    // Create a map to store unique chats by student ID to prevent duplicates
    final Map<String, Map<String, dynamic>> uniqueChats = {};

    // Process all chats and keep only the most recent one per student
    for (final chatDoc in _chats!) {
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);

      // Skip invalid chats
      if (participants.length < 2) continue;

      // Find the other participant (not the current user)
      final otherParticipantId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => 'unknown',
      );

      // Skip if we couldn't find the other participant
      if (otherParticipantId == 'unknown') continue;

      // If this is the first chat with this student or has a newer timestamp, keep it
      if (!uniqueChats.containsKey(otherParticipantId) ||
          _isChatNewer(chatData, uniqueChats[otherParticipantId]!)) {
        uniqueChats[otherParticipantId] = {
          'chatId': chatDoc.id,
          'data': chatData,
          'otherParticipantId': otherParticipantId,
        };
      }
    }

    // If no valid chats remain after filtering
    if (uniqueChats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.blue),
              SizedBox(height: 8),
              Text('No active chats',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('Accept student requests to start chatting',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: uniqueChats.length,
      itemBuilder: (context, index) {
        final chatInfo = uniqueChats.values.toList()[index];
        final chatData = chatInfo['data'] as Map<String, dynamic>;
        final otherParticipantId = chatInfo['otherParticipantId'] as String;

        // Fetch student name
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(otherParticipantId)
              .get(),
          builder: (context, snapshot) {
            // Default values
            String studentName = 'Loading...';
            String? studentProfileUrl;

            // If we have student data, use it
            if (snapshot.hasData && snapshot.data != null) {
              final studentData =
                  snapshot.data!.data() as Map<String, dynamic>?;
              if (studentData != null) {
                studentName =
                    studentData['name'] ?? studentData['fullName'] ?? 'Student';
                studentProfileUrl = studentData['profileImageUrl'];
              }
            } else if (snapshot.connectionState == ConnectionState.done) {
              // If we've tried to load data but failed, use participant name from chat if available
              final participantNames =
                  List<String>.from(chatData['participantNames'] ?? []);
              final participants =
                  List<String>.from(chatData['participants'] ?? []);

              final studentIndex = participants.indexOf(otherParticipantId);
              if (studentIndex >= 0 &&
                  studentIndex < participantNames.length &&
                  participantNames[studentIndex].isNotEmpty) {
                studentName = participantNames[studentIndex];
              } else {
                studentName = 'Unknown Student';
              }
            }

            String lastMessage = chatData['lastMessage'] ?? 'Start chatting...';

            // Format timestamp if available
            String timeAgo = '';
            if (chatData['lastTimestamp'] != null) {
              try {
                final timestamp = chatData['lastTimestamp'] as Timestamp;
                final messageTime = timestamp.toDate();
                timeAgo = _formatTime(messageTime);
              } catch (e) {
                if (kDebugMode) {
                  print('Error formatting timestamp: $e');
                }
                timeAgo = '';
              }
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25), width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: studentProfileUrl != null
                      ? NetworkImage(studentProfileUrl)
                      : null,
                  backgroundColor: const Color(0xFF6C3FD8).withOpacity(0.3),
                  child: studentProfileUrl == null
                      ? Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                title: Text(
                  studentName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    if (timeAgo.isNotEmpty)
                      Text(
                        timeAgo,
                        style: const TextStyle(fontSize: 11, color: Colors.white24),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C3FD8)),
                onTap: () {
                  // Navigate to the chat screen with the student
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        recipientId: otherParticipantId,
                        recipientName: studentName,
                      ),
                    ),
                  ).then((_) {
                    // Refresh chat list when returning from chat screen
                    _loadChats();
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to determine if one chat is newer than another
  bool _isChatNewer(Map<String, dynamic> chat1, Map<String, dynamic> chat2) {
    final timestamp1 =
        chat1['updatedAt'] ?? chat1['lastTimestamp'] ?? chat1['createdAt'];
    final timestamp2 = chat2['data']['updatedAt'] ??
        chat2['data']['lastTimestamp'] ??
        chat2['data']['createdAt'];

    if (timestamp1 == null || timestamp2 == null) return false;

    if (timestamp1 is Timestamp && timestamp2 is Timestamp) {
      return timestamp1.compareTo(timestamp2) > 0;
    }

    return false;
  }

  Widget _buildChatsTabContent() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Center(child: Text('Please log in to view your chats'));
    }

    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Chats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            SizedBox(height: 16),
            _buildActiveChatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTabContent() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Center(child: Text('Please log in to view tutor requests'));
    }

    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requests Received',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Last updated: ${_formatTime(_lastRequestsRefresh)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white30)),
                IconButton(
                  onPressed: _loadRequests,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6C3FD8)),
                  tooltip: 'Refresh requests',
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTabContent() {
    return TutorProfileScreen();
  }

  Widget _buildModulesTabContent() {
    return ModuleSection();
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : const Color(0xFFA78BFA);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: const Color(0xFF6C3FD8).withOpacity(0.15),
          highlightColor: const Color(0xFF6C3FD8).withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? Colors.redAccent : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Tutor Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C3FD8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF6C3FD8),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'My Chats', icon: Icon(Icons.chat_rounded, size: 20)),
            Tab(text: 'My Profile', icon: Icon(Icons.person_rounded, size: 20)),
            Tab(text: 'Requests', icon: Icon(Icons.assignment_ind_rounded, size: 20)),
            Tab(text: 'My Modules', icon: Icon(Icons.book_rounded, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _refreshAll,
            tooltip: 'Refresh All',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A0A0F),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF13131F),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF6C3FD8), width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6C3FD8), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C3FD8).withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF1E1340),
                      radius: 30,
                      child: Icon(Icons.school_rounded, size: 32, color: Color(0xFFA78BFA)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tutor Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Tutor',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Menu items
            _drawerItem(
              icon: Icons.chat_rounded,
              label: 'Messages',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),
            _drawerItem(
              icon: Icons.person_rounded,
              label: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            _drawerItem(
              icon: Icons.assignment_ind_rounded,
              label: 'Requests Received',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(color: const Color(0xFF6C3FD8).withOpacity(0.2), thickness: 1),
            ),
            _drawerItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              isDestructive: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, '/roleSelection');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Chats Tab
            _buildChatsTabContent(),

            // Profile Tab
            _buildProfileTabContent(),

            // Requests Tab
            _buildRequestsTabContent(),

            // Modules Tab
            _buildModulesTabContent(), // Add new tab content
          ],
        ),
      ),
    );
  }
}
