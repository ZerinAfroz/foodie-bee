import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String listingId;
  final String donorId;
  final String distributorId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final List<String> unreadBy;
  final DateTime? createdAt;

  Chat({
    required this.id,
    required this.listingId,
    required this.donorId,
    required this.distributorId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadBy = const [],
    this.createdAt,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      donorId: data['donorId'] as String? ?? '',
      distributorId: data['distributorId'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadBy: List<String>.from(data['unreadBy'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
