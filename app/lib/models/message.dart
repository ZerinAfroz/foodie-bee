import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final bool isRead;
  final bool isDeleted;
  final Map<String, dynamic> readBy;
  final Map<String, dynamic> reactions;
  final DateTime? createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.isRead = false,
    this.isDeleted = false,
    this.readBy = const {},
    this.reactions = const {},
    this.createdAt,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      readBy: (data['readBy'] as Map<String, dynamic>?) ?? {},
      reactions: (data['reactions'] as Map<String, dynamic>?) ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
