// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brainiacz/services/session_service.dart';
import 'package:brainiacz/models/session_model.dart';
import 'package:brainiacz/widgets/session_rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../widgets/session_request_widget.dart';
import '../widgets/active_session_widget.dart';
import '../widgets/request_session_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:brainiacz/services/firestore_services.dart';
import 'package:brainiacz/screens/tutor_profile_screen.dart';
import 'package:brainiacz/screens/student_profile_screen.dart';

// Extension on String for capitalizing first letter
extension StringExtension on String {
  String get capitalizeFirst => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService();
  
  late String _currentUserId;
  bool _isLoading = false;
  SessionModel? _activeSession;
  StreamSubscription<Map<String, dynamic>?>? _ratingSubscription;
  String? _chatId;
  GlobalKey? _messageStreamKey;
  final FocusNode _focusNode = FocusNode();
  StreamSubscription? _sessionRatingSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatId = _getChatId(_currentUserId, widget.recipientId);
    
    // Apply debounce to message stream with custom key
    _messageStreamKey = GlobalKey();
    
    // Set up stream subscription for session rating
    _sessionRatingSubscription = _sessionService.ratingStream.listen((sessionData) {
      if (sessionData != null) {
        _showRatingDialog(
          sessionData['sessionId'],
          sessionData['tutorId'],
          sessionData['duration'],
        );
      }
    });
    
    // Listen to session timer updates
    _sessionService.sessionTimerStream?.listen((duration) {
      if (mounted) {
        setState(() {
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _ratingSubscription?.cancel();
    _sessionRatingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage({String? linkUrl}) async {
    try {
      if ((_messageController.text.trim().isEmpty && linkUrl == null) || _isLoading) {
        return;
      }

      final messageContent = _messageController.text.trim();
      _messageController.clear();
      
      setState(() {
        _isLoading = true;
      });

      // Get current user name
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data();
      final senderName = userData?['fullName'] ?? 'Unknown';
      
      await _firestore.collection('chats').doc(_chatId).collection('messages').add({
        'senderId': _currentUserId,
        'senderName': senderName,
        'receiverId': widget.recipientId,
        'content': messageContent,
        'imageUrl': null,
        'linkUrl': linkUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat document
      await _firestore.collection('chats').doc(_chatId).set({
        'lastMessage': linkUrl != null ? 'Link' : messageContent,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [_currentUserId, widget.recipientId],
        'participantNames': [senderName, widget.recipientName],
      }, SetOptions(merge: true));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to send message: $e');
    }
  }

  Future<void> _addLink() async {
    String? linkUrl;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Link'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter URL',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            linkUrl = value;
          },
          onSubmitted: (value) {
            linkUrl = value;
            Navigator.pop(context);
          },
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
    
    if (linkUrl != null && linkUrl!.isNotEmpty) {
      // Validate and format the URL
      if (!linkUrl!.startsWith('http://') && !linkUrl!.startsWith('https://')) {
        linkUrl = 'https://$linkUrl';
      }
      
      if (kDebugMode) {
        print('Adding link: $linkUrl');
      }
      
      await _sendMessage(linkUrl: linkUrl);
    }
  }

  // Get a unique chat ID based on participant IDs
  String _getChatId(String uid1, String uid2) {
    // Sort the IDs to ensure the same chat ID regardless of who initiates
    List<String> sortedIds = [uid1, uid2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : '?',
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _navigateToProfile(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipientName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Display online status if available
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('users').doc(widget.recipientId).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text(
                            'Loading status...',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          if (kDebugMode) {
                            print('Error loading user status: ${snapshot.error}');
                          }
                          return Text(
                            'Status unavailable',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        }
                        
                        final userData = snapshot.data?.data() as Map<String, dynamic>?;
                        if (userData == null) {
                          return Text(
                            'Offline',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        }
                        
                        final bool isOnline = userData['isOnline'] ?? false;
                        final lastSeen = userData['lastSeen'] as Timestamp?;
                        
                        // Add safeguard for stale 'isOnline' status
                        // If lastSeen is more than 2 minutes ago, consider user offline
                        // regardless of isOnline flag (handles app crashes or force closes)
                        if (isOnline && lastSeen != null) {
                          final lastSeenDate = lastSeen.toDate();
                          final now = DateTime.now();
                          final difference = now.difference(lastSeenDate);
                          
                          // If last activity was more than 2 minutes ago, consider user offline
                          if (difference.inMinutes > 2) {
                            // Display last seen time instead of "Online"
                            String lastSeenText;
                            if (difference.inMinutes < 60) {
                              lastSeenText = 'Last seen ${difference.inMinutes} min ago';
                            } else if (difference.inHours < 24) {
                              lastSeenText = 'Last seen ${difference.inHours} hr ago';
                            } else {
                              lastSeenText = 'Last seen ${DateFormat('MMM d').format(lastSeenDate)}';
                            }
                            
                            return Text(
                              lastSeenText,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            );
                          }
                        }
                        
                        if (isOnline) {
                          return Text(
                            'Online',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          );
                        } else if (lastSeen != null) {
                          final lastSeenDate = lastSeen.toDate();
                          final now = DateTime.now();
                          final difference = now.difference(lastSeenDate);
                          
                          String lastSeenText;
                          if (difference.inMinutes < 60) {
                            lastSeenText = 'Last seen ${difference.inMinutes} min ago';
                          } else if (difference.inHours < 24) {
                            lastSeenText = 'Last seen ${difference.inHours} hr ago';
                          } else {
                            lastSeenText = 'Last seen ${DateFormat('MMM d').format(lastSeenDate)}';
                          }
                          
                          return Text(
                            lastSeenText,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        } else {
                          return Text(
                            'Offline',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            onPressed: _showReportUserDialog,
            tooltip: 'Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Session Display (if any)
          StreamBuilder<List<SessionModel>>(
            stream: _firestore
                .collection('sessions')
                .where('status', isEqualTo: SessionStatus.active.toString().split('.').last)
                .where('participants', arrayContains: _currentUserId)
                .snapshots()
                .map((snapshot) {
                  final sessions = snapshot.docs
                      .map((doc) => SessionModel.fromMap({...doc.data(), 'id': doc.id}))
                      .where((session) => 
                          (session.requesterId == _currentUserId && 
                           session.recipientId == widget.recipientId) ||
                          (session.recipientId == _currentUserId && 
                           session.requesterId == widget.recipientId))
                      .toList();
                  
                  // Cache the first session if available
                  if (sessions.isNotEmpty && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _activeSession = sessions.first;
                      });
                      // Only start timer if this is a new session or status has changed
                      if (_sessionService.sessionTimerStream == null) {
                        _sessionService.startSessionTimer(sessions.first);
                      }
                    });
                  }
                  return sessions;
                }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _activeSession == null) {
                return SizedBox(
                  height: 60,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              
              if ((snapshot.hasData && snapshot.data!.isNotEmpty) || _activeSession != null) {
                // Use either the new data or cached data
                final session = snapshot.hasData && snapshot.data!.isNotEmpty 
                    ? snapshot.data!.first 
                    : _activeSession!;
                
                return ActiveSessionWidget(
                  session: session,
                  onEndSession: () => _handleEndSession(session.id),
                  currentUserId: _currentUserId,
                );
              }
              return Container(); // No active session
            },
          ),
          // Session Request Display (if any)
          StreamBuilder<List<SessionModel>>(
            stream: _firestore
                .collection('sessions')
                .where('status', isEqualTo: SessionStatus.requested.toString().split('.').last)
                .where('participants', arrayContains: _currentUserId)
                .snapshots()
                .map((snapshot) {
                  return snapshot.docs
                      .map((doc) => SessionModel.fromMap({...doc.data(), 'id': doc.id}))
                      .where((session) => 
                          session.recipientId == _currentUserId && 
                          session.requesterId == widget.recipientId)
                      .toList();
                }),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final session = snapshot.data!.first;
                return SessionRequestWidget(
                  session: session,
                  onAccept: () => _handleAcceptSession(session.id),
                  onDecline: () => _handleDeclineSession(session.id),
                );
              }
              return Container(); // No session request
            },
          ),
          // Session request button - only show for students
          if (_activeSession == null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(_currentUserId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink();
                }
                
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final userRole = userData?['role'] as String? ?? '';
                  
                  // Only show the session request button if the user is a student
                  if (userRole.toLowerCase() == 'student') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: _showRequestSessionDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Request Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                
                // Don't show the button for tutors
                return SizedBox.shrink();
              },
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: _messageStreamKey,
              stream: _firestore
                .collection('chats')
                .doc(_chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(50) // Limit to avoid excessive loading
                .snapshots(),
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting && 
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Handle error state
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }
                
                // Handle empty state
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation with ${widget.recipientName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                
                // Process message errors gracefully
                try {
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic>? messageData;
                      
                      try {
                        messageData = messages[index].data() as Map<String, dynamic>;
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error parsing message data: $e');
                        }
                        return Container(); // Skip invalid messages
                      }
                      
                      final senderId = messageData['senderId'] as String? ?? 'unknown';
                      final isMe = senderId == _currentUserId;
                      final isSystem = senderId == 'system';
                      
                      // Mark message as read if it's not from current user, but only once
                      if (!isMe && !isSystem && messageData['isRead'] == false) {
                        try {
                          // Use a batch write to efficiently update read status
                          // This avoids triggering multiple updates
                          final WriteBatch batch = FirebaseFirestore.instance.batch();
                          batch.update(messages[index].reference, {'isRead': true});
                          batch.commit().catchError((e) {
                            if (kDebugMode) {
                              print('Error marking message as read: $e');
                            }
                          });
                        } catch (e) {
                          if (kDebugMode) {
                            print('Error marking message as read: $e');
                          }
                        }
                      }

                      return _buildMessageBubble(
                        message: messageData['content'] as String? ?? '',
                        isMe: isMe,
                        isSystem: isSystem,
                        imageUrl: messageData['imageUrl'] as String?,
                        linkUrl: messageData['linkUrl'] as String?,
                        timestamp: messageData['timestamp'],
                        senderName: messageData['senderName'] as String?,
                      );
                    },
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print('Error building message list: $e');
                  }
                  return Center(
                    child: Text('Error loading messages: $e'),
                  );
                }
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    bool isSystem = false,
    String? imageUrl,
    String? linkUrl,
    dynamic timestamp,
    String? senderName,
  }) {
    // Format timestamp if available
    String timeText = '';
    if (timestamp != null) {
      try {
        final DateTime dateTime = timestamp is Timestamp 
            ? timestamp.toDate() 
            : (timestamp is DateTime ? timestamp : DateTime.now());
        
        timeText = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        print('Error formatting timestamp: $e');
      }
    }
    
    return Align(
      alignment: isSystem 
          ? Alignment.center 
          : (isMe ? Alignment.centerRight : Alignment.centerLeft),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            padding: EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isSystem 
                  ? Colors.grey[300] 
                  : (isMe ? Colors.blue[100] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe && !isSystem ? Radius.circular(5) : Radius.circular(20),
                bottomLeft: !isMe && !isSystem ? Radius.circular(5) : Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Open full-screen image view
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  iconTheme: IconThemeData(color: Colors.white),
                                ),
                                body: Center(
                                  child: InteractiveViewer(
                                    panEnabled: true,
                                    boundaryMargin: EdgeInsets.all(20),
                                    minScale: 0.5,
                                    maxScale: 3.0,
                                    child: Image.network(
                                      imageUrl,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    (loadingProgress.expectedTotalBytes ?? 1)
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        if (kDebugMode) {
                                          print('Error displaying image in full view: $error');
                                        }
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                                            SizedBox(height: 16),
                                            Text(
                                              'Error loading image',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 200,
                            maxHeight: 200,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Loading image...',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              if (kDebugMode) {
                                print('Error loading image in chat bubble: $error');
                              }
                              return Container(
                                width: 200,
                                height: 120,
                                color: Colors.grey.shade200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.red, size: 36),
                                    SizedBox(height: 8),
                                    Text(
                                      'Image failed to load',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                    ),
                                    SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        // Force refresh with setState
                                        if (mounted) setState(() {});
                                      },
                                      child: Text('Retry', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to view full image',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (message.isNotEmpty) 
                  Text(
                    message,
                    style: isSystem 
                        ? TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 14)
                        : TextStyle(fontSize: 16),
                  ),
                if (timeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      textAlign: isMe ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                if (linkUrl != null)
                  InkWell(
                    onTap: () async {
                      try {
                        final uri = Uri.parse(linkUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (kDebugMode) {
                            print('Could not launch URL: $linkUrl');
                          }
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cannot open this link')),
                          );
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error launching URL: $e');
                        }
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid URL format')),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        // ignore: deprecated_member_use
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Link',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            linkUrl,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row with attachment options
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.link, color: Colors.blue),
                  onPressed: _addLink,
                  tooltip: 'Add link',
                ),
                Spacer(),
                // Only show session request button for students, not for tutors
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(_currentUserId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    }
                    
                    if (snapshot.hasData) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      final userRole = userData?['role'] as String? ?? '';
                      
                      // Only show the request session button if the user is a student
                      if (userRole.toLowerCase() == 'student') {
                        return TextButton.icon(
                          icon: Icon(Icons.event_note, color: Colors.blue),
                          label: Text('Request Session'),
                          onPressed: _showRequestSessionDialog,
                        );
                      }
                    }
                    
                    // Don't show the button for tutors
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            // Message input field and send button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  void _showReportUserDialog() {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Inappropriate behavior';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report User'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What issues are you experiencing with ${widget.recipientName}?'),
                  SizedBox(height: 16),
                  
                  // Predefined reasons
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedReason,
                    items: [
                      'Inappropriate behavior',
                      'Harassment',
                      'Poor teaching quality',
                      'No-show for session',
                      'Abusive language',
                      'Other',
                    ].map((reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedReason = value;
                        });
                      }
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Additional details
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Additional Details',
                      hintText: 'Please provide more information...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: 8),
                  Text(
                    'User reports are anonymous. Our team will review this report promptly.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                final currentUserDoc = await _firestore.collection('users').doc(_currentUserId).get();
                final currentUserData = currentUserDoc.data();
                final reporterName = currentUserData?['name'] ?? currentUserData?['fullName'] ?? 'Unknown';
                
                final recipientDoc = await _firestore.collection('users').doc(widget.recipientId).get();
                final recipientData = recipientDoc.data();
                final recipientRole = recipientData?['role'] ?? 'student';
                
                // Get FirestoreService instance from Provider
                // ignore: use_build_context_synchronously
                final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                await firestoreService.reportUser(
                  reporterId: _currentUserId,
                  reporterName: reporterName,
                  reportedUserId: widget.recipientId,
                  reportedUserName: widget.recipientName,
                  reportedUserRole: recipientRole,
                  reason: selectedReason,
                  additionalInfo: reasonController.text.trim(),
                );
                
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for your report. Our team will review it.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to submit report. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
                if (kDebugMode) {
                  print('Error reporting user: $e');
                }
              }
            },
            child: Text('Submit Report'),
          ),
        ],
      ),
    );
  }
  
  void _showRequestSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => RequestSessionDialog(
        onRequestSession: (durationMinutes) {
          _sessionService.requestSession(
            recipientId: widget.recipientId,
            durationMinutes: durationMinutes,
          );
        },
      ),
    );
  }

  // Show rating dialog for completed sessions
  void _showRatingDialog(String sessionId, String tutorId, String sessionDuration) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must rate the tutor
      builder: (context) => SessionRatingDialog(
        tutorId: tutorId,
        sessionId: sessionId,
        sessionDuration: sessionDuration,
        onRatingSubmitted: (rating) async {
          try {
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Submitting rating...'))
            );
            
            // Submit the rating
            await _sessionService.submitTutorRating(
              sessionId: sessionId,
              rating: rating.toDouble(), // Convert int to double
              tutorId: tutorId,
            );
            
            if (mounted) {
              // Close dialog after successful submission
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              
              // Show success message
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!'))
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error submitting rating: $e');
            }
            
            if (mounted) {
              // Check if the error is because the session was already rated
              if (e.toString().contains('already been rated')) {
                // Close the dialog since rating is not needed
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                
                // Show informative message
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You have already rated this session'))
                );
              } else {
                // Show error message but don't close dialog so user can try again
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error submitting rating: $e'))
                );
              }
            }
          }
        },
      ),
    );
  }

  // Handle accept session
  void _handleAcceptSession(String sessionId) async {
    try {
      await _sessionService.acceptSession(sessionId);
      _showSnackBar('Session accepted');
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting session: $e');
      }
      _showSnackBar('Error accepting session: $e');
    }
  }
  
  // Handle decline session
  void _handleDeclineSession(String sessionId) async {
    try {
      await _sessionService.declineSession(sessionId);
      _showSnackBar('Session declined');
    } catch (e) {
      if (kDebugMode) {
        print('Error declining session: $e');
      }
      _showSnackBar('Error declining session: $e');
    }
  }
  
  // Handle end session
  void _handleEndSession(String sessionId) async {
    try {
      await _sessionService.endSession(sessionId);
      _showSnackBar('Session ended');
    } catch (e) {
      if (kDebugMode) {
        print('Error ending session: $e');
      }
      _showSnackBar('Error ending session: $e');
    }
  }

  // Show a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToProfile() async {
    final recipientDoc = await _firestore.collection('users').doc(widget.recipientId).get();
    final recipientData = recipientDoc.data();
    final recipientRole = recipientData?['role'] ?? '';

    if (recipientRole.toLowerCase() == 'tutor') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => TutorProfileScreen(tutorId: widget.recipientId)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => StudentProfileScreen(studentId: widget.recipientId)),
      );
    }
  }
}
