//lib/screens/student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainiacz/screens/tutor_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'search_results_screen.dart';
import 'chat_screen.dart';

// Helper function to capitalize the first letter of a string
String capitalizeString(String input) {
  if (input.isEmpty) return input;
  return '${input[0].toUpperCase()}${input.substring(1)}';
}

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with TickerProviderStateMixin {
  final _requestsKey = GlobalKey();

  List<QueryDocumentSnapshot<Object?>>? _requests;
  List<QueryDocumentSnapshot<Object?>>? _chats;
  bool _isLoading = false;
  DateTime _lastRequestsRefresh = DateTime.now();
  DateTime _lastChatsRefresh = DateTime.now();

  // Tab controller for different sections
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Update length from 2 to 3 tabs
    _tabController = TabController(length: 3, vsync: this);
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _lastRequestsRefresh = DateTime.now();
      });
    }

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw 'No user logged in';
      }

      // Query your tutor requests collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('studentId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _requests = querySnapshot.docs;
          _isLoading = false;
        });
      }

      // Process any accepted requests to ensure chats exist
      await _processAcceptedRequests();

      // Reload chats after processing accepted requests
      await _loadChats();

      if (kDebugMode) {
        print('Loaded ${querySnapshot.docs.length} requests');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load requests: $e'),
          backgroundColor: Colors.red,
        ));
      }
      if (kDebugMode) {
        print('Error loading requests: $e');
      }
    }
  }

  // Load chats data manually
  Future<void> _loadChats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _lastChatsRefresh = DateTime.now();
      });
    }

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw 'No user logged in';
      }

      // Query chats where the current user is a participant
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _chats = querySnapshot.docs;
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print('Loaded ${querySnapshot.docs.length} chats');
      }

      // Check if there are any accepted requests but no chats
      if (_requests != null) {
        final hasAcceptedRequests = _requests!.any((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'accepted';
        });

        // If we have accepted requests but no chats, something might be wrong
        // Let's process accepted requests to ensure chats exist
        if (hasAcceptedRequests && (_chats == null || _chats!.isEmpty)) {
          if (kDebugMode) {
            print(
                'Found accepted requests but no chats. Reprocessing requests...');
          }
          await _processAcceptedRequests();
          // Reload chats again after fixing any missing chats
          await _loadChats();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load chats: $e'),
          backgroundColor: Colors.red,
        ));
      }
      if (kDebugMode) {
        print('Error loading chats: $e');
      }
    }
  }

  // Refresh the UI state - manually load new data
  Future<void> _refreshAll() async {
    if (kDebugMode) {
      print('Performing full refresh of student dashboard');
    }

    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Reload requests then chats
      await _loadRequests();
      await _loadChats();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dashboard refreshed'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error refreshing: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Process accepted requests to ensure chats exist
  Future<void> _processAcceptedRequests() async {
    if (_requests == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Find all accepted requests
    final acceptedRequests = _requests!.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'accepted';
    }).toList();

    if (kDebugMode) {
      print('Processing ${acceptedRequests.length} accepted requests');
    }

    bool chatsCreated = false;

    // For each accepted request, ensure a chat exists
    for (final doc in acceptedRequests) {
      final data = doc.data() as Map<String, dynamic>;
      final tutorId = data['tutorId'];

      // Create a unique chat ID
      final chatId = currentUserId.compareTo(tutorId) < 0
          ? '$currentUserId-$tutorId'
          : '$tutorId-$currentUserId';

      final chatExisted = await _chatExists(chatId);
      if (!chatExisted) {
        await _ensureChatExists(currentUserId, tutorId, chatId);
        chatsCreated = true;
      }
    }

    // If we created new chats, switch to the chats tab
    if (chatsCreated && mounted) {
      // Switch to the chats tab after a brief delay
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _tabController.animateTo(0); // Switch to chats tab

          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Request accepted! Chat created in Messages tab.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ));
        }
      });
    }

    // After processing accepted requests, refresh the chat list
    if (chatsCreated) {
      await _loadChats();
    }
  }

  // Helper to check if a chat exists
  Future<bool> _chatExists(String chatId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if chat exists: $e');
      }
      return false;
    }
  }

  // Ensure a chat exists between the student and tutor
  Future<void> _ensureChatExists(
      String studentId, String tutorId, String chatId) async {
    try {
      // Check if chat already exists
      final existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!existingChat.exists) {
        if (kDebugMode) {
          print('Creating new chat: $chatId between $studentId and $tutorId');
        }

        // Get user names
        String studentName = 'Student';
        String tutorName = 'Tutor';

        try {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          if (studentDoc.exists) {
            final studentData = studentDoc.data() as Map<String, dynamic>;
            studentName = studentData['name'] ?? 'Student';
          }

          final tutorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(tutorId)
              .get();
          if (tutorDoc.exists) {
            final tutorData = tutorDoc.data() as Map<String, dynamic>;
            tutorName = tutorData['name'] ?? 'Tutor';
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting participant names: $e');
          }
        }

        // Create the chat document if it doesn't exist
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'participants': [studentId, tutorId],
          'participantNames': [studentName, tutorName],
          'lastMessage': 'Chat created',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('Chat created successfully');
        }
      } else {
        if (kDebugMode) {
          print('Chat already exists: $chatId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring chat exists: $e');
      }
    }
  }

  Widget _buildMyRequestsSection(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(
        child: Text('You must be logged in to view your requests'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildRequestsList(context, currentUserId),
      ],
    );
  }

  Widget _buildRequestsList(BuildContext context, String currentUserId) {
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
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No tutoring requests found',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    final requests = _requests!;
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index].data() as Map<String, dynamic>;
        final tutorId = request['tutorId'];
        final status = request['status'];
        final subject = request['subject'];
        final sessionDate = _formatDate(request['sessionDate']);
        final sessionTime = request['sessionTime'];

        // Different card colors based on status
        Color cardColor;
        IconData statusIcon;

        switch (status) {
          case 'accepted':
            cardColor = Colors.green.shade50;
            statusIcon = Icons.check_circle;
            break;
          case 'rejected':
            cardColor = Colors.red.shade50;
            statusIcon = Icons.cancel;
            break;
          case 'pending':
          default:
            cardColor = Colors.orange.shade50;
            statusIcon = Icons.hourglass_empty;
            break;
        }

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(tutorId).get(),
          builder: (context, tutorSnapshot) {
            String tutorName = 'Loading...';
            String? profileImageUrl;

            if (tutorSnapshot.hasData && tutorSnapshot.data != null) {
              final tutorData =
                  tutorSnapshot.data!.data() as Map<String, dynamic>?;
              tutorName = tutorData?['name'] ?? 'Unknown Tutor';
              profileImageUrl = tutorData?['profileImageUrl'];
            }

            return Card(
              color: cardColor,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null ? Text(tutorName[0]) : null,
                ),
                title: Text(tutorName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$subject - $sessionDate at $sessionTime'),
                    Row(
                      children: [
                        Icon(statusIcon, size: 14),
                        SizedBox(width: 4),
                        Text(capitalizeString(status),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    // Show a note for accepted requests pointing to My Chats
                    if (status == 'accepted')
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Chat available in Messages tab',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Remove message button for accepted requests
                trailing: status == 'accepted'
                    ? IconButton(
                        icon: Icon(Icons.tab, color: Colors.blue),
                        tooltip: 'Go to Messages tab',
                        onPressed: () {
                          // Switch to the chats tab
                          _tabController.animateTo(0);
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyChatsSection(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Chats',
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
                      print("Manual refresh of chats requested");
                    }
                    _loadChats();
                  },
                  tooltip: 'Refresh chats',
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildChatsList(context, currentUserId),
      ],
    );
  }

  Widget _buildChatsList(BuildContext context, String currentUserId) {
    if (currentUserId.isEmpty) return SizedBox.shrink();

    // Initialize _chats to empty list if null to prevent loading issues
    if (_chats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No chats loaded'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadChats,
              child: Text('Load Chats'),
            ),
          ],
        ),
      );
    }

    if (_chats!.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.blue),
            SizedBox(height: 8),
            Text('No active chats',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Search for tutors to start chatting',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final chats = _chats!;
    return ListView.builder(
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        // Use try-catch to handle potential data errors
        try {
          final chatDoc = chats[index];
          final chatData = chatDoc.data() as Map<String, dynamic>;

          // Handle nullable values to prevent crashes
          final participants =
              List<String>.from(chatData['participants'] ?? []);
          if (participants.isEmpty) {
            if (kDebugMode) {
              print('Warning: Chat ${chatDoc.id} has no participants');
            }
            return SizedBox.shrink(); // Skip invalid chats
          }

          // Find the other participant (not the current user)
          String otherParticipantId = 'Unknown';
          try {
            otherParticipantId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => 'Unknown',
            );
          } catch (e) {
            if (kDebugMode) {
              print('Error finding other participant: $e');
            }
          }

          // Get the participant names
          final participantNames =
              List<String>.from(chatData['participantNames'] ?? []);
          String otherParticipantName = 'Unknown';

          // Find the name of the other participant
          if (participants.isNotEmpty && participantNames.isNotEmpty) {
            final otherIndex = participants.indexOf(otherParticipantId);
            if (otherIndex >= 0 && otherIndex < participantNames.length) {
              otherParticipantName = participantNames[otherIndex];
            }
          }

          // Get last message preview text
          final String lastMessage =
              chatData['lastMessage'] as String? ?? 'Start chatting...';

          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  otherParticipantName.isNotEmpty
                      ? otherParticipantName[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
              title: Text(
                otherParticipantName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      recipientId: otherParticipantId,
                      recipientName: otherParticipantName,
                    ),
                  ),
                ).then((_) {
                  // Refresh chat list when returning from chat screen
                  _loadChats();
                });
              },
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error rendering chat at index $index: $e');
          }
          return SizedBox.shrink(); // Skip problematic chat entries
        }
      },
    );
  }

  String _formatDate(dynamic dateInput) {
    try {
      DateTime date;
      if (dateInput is String) {
        // Handle ISO8601 string format
        date = DateTime.parse(dateInput);
      } else if (dateInput is Timestamp) {
        // Handle Firestore Timestamp
        date = dateInput.toDate();
      } else {
        // Try to convert to string and parse
        date = DateTime.parse(dateInput.toString());
      }

      return DateFormat('MMM d, yyyy').format(date); // e.g., "Mar 7, 2025"
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting date: $e');
      }
      return dateInput?.toString() ?? 'No date';
    }
  }

  // Helper function to format refresh time
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

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Search for Tutors'),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Enter subject (e.g. Math, Science)',
            hintText: 'Enter a subject to find tutors',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(dialogContext);
            if (query.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsScreen(searchQuery: query),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = searchController.text.trim();
              Navigator.pop(dialogContext);
              if (query.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchResultsScreen(searchQuery: query),
                  ),
                );
              }
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Chats', icon: Icon(Icons.chat)),
            Tab(text: 'My Requests', icon: Icon(Icons.history)),
            Tab(text: 'Tutor Suggestions', icon: Icon(Icons.recommend)),
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
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Student Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Student',
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
              title: Text('User Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to the student profile screen
                Navigator.pushNamed(context, '/studentProfile');
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search Tutors'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to a search input screen instead of results directly
                _showSearchDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('My Requests'),
              onTap: () {
                Navigator.pop(context);
                // Switch to requests tab
                _tabController.animateTo(1);
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
            // Chats Tab - Only show chats, no requests
            _buildChatsTabContent(context),

            // Requests Tab
            _buildRequestsTabContent(context),
            _buildTutorSuggestionsContent(context), // Add new tab content
          ],
        ),
      ),
    );
  }

  // Build the Chats tab content
  Widget _buildChatsTabContent(BuildContext context) {
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
            SizedBox(height: 20),
            _buildMyChatsSection(context),
            SizedBox(height: 20),

            // Show search for tutor button only if no chats exist
            if (_chats == null || _chats!.isEmpty) _buildFindTutorCard(),
          ],
        ),
      ),
    );
  }

  // Build the "Find a Tutor" card that appears when no chats exist
  Widget _buildFindTutorCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.search, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Find a Tutor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Connect with qualified tutors to help with your studies',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Use the same search dialog as the menu item
                _showSearchDialog(context);
              },
              icon: Icon(Icons.search),
              label: Text('Search for Tutors'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the Requests tab content
  Widget _buildRequestsTabContent(BuildContext context) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show the title without any Create Request button
            Text(
              'My Requests',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Just show the requests section directly
            Container(
              key: _requestsKey,
              child: _buildMyRequestsSection(context),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method for the Tutor Suggestions tab content:
  Widget _buildTutorSuggestionsContent(BuildContext context) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested Tutors',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'tutor')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final tutors = snapshot.data?.docs ?? [];

                if (tutors.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.person_search, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No tutors available',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Sort tutors by rating (null ratings go to the end)
                final sortedTutors = List.from(tutors);
                sortedTutors.sort((a, b) {
                  final ratingA = (a.data() as Map<String, dynamic>)['rating']
                          ?.toDouble() ??
                      -1;
                  final ratingB = (b.data() as Map<String, dynamic>)['rating']
                          ?.toDouble() ??
                      -1;
                  return ratingB.compareTo(ratingA); // Descending order
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: sortedTutors.length,
                  itemBuilder: (context, index) {
                    final tutorDoc = sortedTutors[index];
                    final tutorData = tutorDoc.data() as Map<String, dynamic>;
                    final tutorName = tutorData['name'] ??
                        tutorData['displayName'] ??
                        'No name';
                    final rating = tutorData['rating']?.toDouble();

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            tutorName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tutorName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Show rating or "New" badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: rating != null
                                    ? Colors.amber.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    rating != null
                                        ? Icons.star
                                        : Icons.new_releases,
                                    size: 16,
                                    color: rating != null
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    rating != null
                                        ? rating.toStringAsFixed(1)
                                        : 'New',
                                    style: TextStyle(
                                      color: rating != null
                                          ? Colors.amber[900]
                                          : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tutorData['email'] ?? 'No email'),
                            if (tutorData['subjects'] != null)
                              Text(
                                  'Subjects: ${(tutorData['subjects'] as List).join(', ')}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorDetailsScreen(
                                  tutor: {
                                    ...tutorData,
                                    'id': tutorDoc
                                        .id, // Add the tutor's document ID
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text('View Profile'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
