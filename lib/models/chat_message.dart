// lib/models/chat_message.dart
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    this.linkUrl,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'],
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      content: data['content'],
      imageUrl: data['imageUrl'],
      linkUrl: data['linkUrl'],
      timestamp: data['timestamp'].toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}
