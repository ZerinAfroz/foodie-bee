import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  bool isLoading = false;

  Future<String> findOrCreateChat({
    required String listingId,
    required String donorId,
    required String distributorId,
  }) async {
    return await _chatService.findOrCreateChat(
      listingId: listingId,
      donorId: donorId,
      distributorId: distributorId,
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: text,
    );

    await _writeChatNotification(
      chatId: chatId,
      senderId: senderId,
      text: text,
    );
  }

  Stream<QuerySnapshot> getChatsForUser(String userId) {
    return _chatService.getChatsForUser(userId);
  }

  Stream<QuerySnapshot> getChatsForUserAsDistributor(String userId) {
    return _chatService.getChatsForUserAsDistributor(userId);
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _chatService.getMessages(chatId);
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _chatService.markAsRead(chatId, userId);
  }

  Stream<int> unreadChatCountStream(String userId) {
    return _chatService.unreadChatCountStream(userId);
  }

  Future<String> getOtherUserName(String otherUserId) async {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(otherUserId)
        .get();
    final data = doc.data();
    return data?['name'] as String? ?? '';
  }

  Future<String> getListingTitle(String listingId) async {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionFoodListings)
        .doc(listingId)
        .get();
    final data = doc.data();
    return data?['title'] as String? ?? '';
  }

  Future<void> _writeChatNotification({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final chatDoc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .doc(chatId)
        .get();
    final chatData = chatDoc.data();
    if (chatData == null) return;

    final donorId = chatData['donorId'] as String? ?? '';
    final distributorId = chatData['distributorId'] as String? ?? '';
    final recipientId = senderId == donorId ? distributorId : donorId;

    final senderDoc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(senderId)
        .get();
    final senderName =
        (senderDoc.data()?['name'] as String?) ?? 'Someone';

    final listingId = chatData['listingId'] as String? ?? '';

    await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .add({
      'userId': recipientId,
      'title': 'New Message',
      'body': '$senderName: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}',
      'type': 'chat_message',
      'listingId': listingId,
      'chatId': chatId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
