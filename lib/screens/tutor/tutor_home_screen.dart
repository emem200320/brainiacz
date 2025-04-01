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
                cardColor = Colors.green.shade50;
                actionButtons = Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.chat),
                      label: Text('Open Chat'),
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
                cardColor = Colors.red.shade50;
                actionButtons = Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Request declined',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey)),
                );
                break;
              case 'pending':
              default:
                cardColor = Colors.orange.shade50;
                actionButtons = Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to a limited student profile view
                        _showStudentProfile(studentId);
                      },
                      child: Text('View Profile'),
                    ),
                    SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () async {
                        // Reject request
                        await FirebaseFirestore.instance
                            .collection('requests')
                            .doc(requestId)
                            .update({
                          'status': 'rejected',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        // Reload data
                        _loadRequests();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: Text('Decline'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _acceptRequest(requestId, studentId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Accept'),
                    ),
                  ],
                );
                break;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 10),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: studentProfileUrl != null
                              ? NetworkImage(studentProfileUrl)
                              : null,
                          child: studentProfileUrl == null
                              ? Text(
                                  studentName.isNotEmpty ? studentName[0] : '?')
                              : null,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  '$subject - $formattedSessionDate at $sessionTime'),
                              Text('Status: $status',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text('Last updated: ${_formatTime(_lastChatsRefresh)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue),
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

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: studentProfileUrl != null
                      ? NetworkImage(studentProfileUrl)
                      : null,
                  backgroundColor: Colors.blue.shade100,
                  child: studentProfileUrl == null
                      ? Text(studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?')
                      : null,
                ),
                title: Text(studentName),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeAgo.isNotEmpty)
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
            Text(
              'My Chats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Last updated: ${_formatTime(_lastRequestsRefresh)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  onPressed: _loadRequests,
                  icon: Icon(Icons.refresh, size: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Tutor Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Chats', icon: Icon(Icons.chat)),
            Tab(text: 'My Profile', icon: Icon(Icons.person)),
            Tab(text: 'Requests', icon: Icon(Icons.assignment_ind)),
            Tab(text: 'My Modules', icon: Icon(Icons.book)), // Add new tab
          ],
        ),
        actions: [
          // Add a refresh button to the app bar
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh All',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.school, size: 40, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tutor Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Tutor',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                // Switch to messages tab
                _tabController.animateTo(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                // Switch to profile tab
                _tabController.animateTo(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment_ind),
              title: Text('Requests Received'),
              onTap: () {
                Navigator.pop(context);
                // Switch to requests tab
                _tabController.animateTo(2);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
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
