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
                style: const TextStyle(fontSize: 12, color: Colors.white30)),
            IconButton(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6C3FD8)),
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
            cardColor = const Color(0xFF0D1F14);
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'rejected':
            cardColor = const Color(0xFF1F0D0D);
            statusIcon = Icons.cancel_rounded;
            break;
          case 'pending':
          default:
            cardColor = const Color(0xFF13131F);
            statusIcon = Icons.hourglass_empty_rounded;
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C3FD8).withOpacity(0.2),
                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl == null
                      ? Text(tutorName[0], style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w700))
                      : null,
                ),
                title: Text(tutorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('$subject · $sessionDate at $sessionTime', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 14, color: status == 'accepted' ? Colors.greenAccent : status == 'rejected' ? Colors.redAccent : const Color(0xFFA78BFA)),
                        const SizedBox(width: 4),
                        Text(capitalizeString(status), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: status == 'accepted' ? Colors.greenAccent : status == 'rejected' ? Colors.redAccent : const Color(0xFFA78BFA))),
                      ],
                    ),
                    if (status == 'accepted')
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFA78BFA)),
                            SizedBox(width: 4),
                            Text('Chat available in Messages tab', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: status == 'accepted'
                    ? IconButton(
                        icon: const Icon(Icons.tab_rounded, color: Color(0xFF6C3FD8)),
                        tooltip: 'Go to Messages tab',
                        onPressed: () => _tabController.animateTo(0),
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
            const Text(
              'My Chats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            Row(
              children: [
                Text('Last updated: ${_formatTime(_lastChatsRefresh)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white30)),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C3FD8)),
                  onPressed: () { _loadChats(); },
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
            const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white38),
            const SizedBox(height: 8),
            const Text('No active chats', style: TextStyle(fontSize: 16, color: Colors.white38)),
            const Text('Search for tutors to start chatting', style: TextStyle(color: Colors.white24)),
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

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF13131F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6C3FD8).withOpacity(0.3),
                child: Text(
                  otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(
                otherParticipantName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6C3FD8)),
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
                Text(label, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
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
          'Student Dashboard',
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
            Tab(text: 'My Requests', icon: Icon(Icons.history_rounded, size: 20)),
            Tab(text: 'Tutor Suggestions', icon: Icon(Icons.recommend_rounded, size: 20)),
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
                      child: Icon(Icons.person_rounded, size: 32, color: Color(0xFFA78BFA)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Student Menu',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'Student',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _drawerItem(icon: Icons.chat_rounded, label: 'Messages', onTap: () { Navigator.pop(context); _tabController.animateTo(0); }),
            _drawerItem(icon: Icons.person_rounded, label: 'User Profile', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/studentProfile'); }),
            _drawerItem(icon: Icons.search_rounded, label: 'Search Tutors', onTap: () { Navigator.pop(context); _showSearchDialog(context); }),
            _drawerItem(icon: Icons.assignment_rounded, label: 'My Requests', onTap: () { Navigator.pop(context); _tabController.animateTo(1); }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(color: const Color(0xFF6C3FD8).withOpacity(0.2), thickness: 1),
            ),
            _drawerItem(icon: Icons.logout_rounded, label: 'Logout', isDestructive: true, onTap: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/roleSelection');
            }),
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
            const Text(
              'My Chats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 20),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.search_rounded, size: 48, color: Color(0xFFA78BFA)),
          const SizedBox(height: 16),
          const Text('Find a Tutor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Connect with qualified tutors to help with your studies', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search for Tutors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3FD8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: const Color(0xFF6C3FD8).withOpacity(0.45),
            ),
          ),
        ],
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
            const Text(
              'My Requests',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 20),
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
            const Text(
              'Suggested Tutors',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
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
                      children: const [
                        Icon(Icons.person_search_rounded, size: 48, color: Colors.white38),
                        SizedBox(height: 8),
                        Text('No tutors available', style: TextStyle(color: Colors.white38)),
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

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6C3FD8).withOpacity(0.25), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF6C3FD8).withOpacity(0.2),
                              child: Text(
                                tutorName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 18, color: Color(0xFFA78BFA), fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(tutorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: rating != null ? Colors.amber.withOpacity(0.15) : const Color(0xFF6C3FD8).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(rating != null ? Icons.star_rounded : Icons.new_releases_rounded, size: 14, color: rating != null ? Colors.amber : const Color(0xFFA78BFA)),
                                            const SizedBox(width: 3),
                                            Text(rating != null ? rating.toStringAsFixed(1) : 'New', style: TextStyle(color: rating != null ? Colors.amber : const Color(0xFFA78BFA), fontWeight: FontWeight.w700, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(tutorData['email'] ?? 'No email', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  if (tutorData['subjects'] != null)
                                    Text('Subjects: ${(tutorData['subjects'] as List).join(', ')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => TutorDetailsScreen(tutor: {...tutorData, 'id': tutorDoc.id})));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C3FD8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('View', style: TextStyle(fontSize: 13)),
                            ),
                          ],
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
