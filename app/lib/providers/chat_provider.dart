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
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: text,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSender: replyToSender,
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

  Future<void> pinChat(String chatId, String userId) async {
    await _chatService.pinChat(chatId, userId);
  }

  Future<void> muteChat(String chatId, String userId) async {
    await _chatService.muteChat(chatId, userId);
  }

  Future<void> archiveChat(String chatId, String userId) async {
    await _chatService.archiveChat(chatId, userId);
  }

  Future<void> unarchiveChat(String chatId, String userId) async {
    await _chatService.unarchiveChat(chatId, userId);
  }

  Future<void> deleteChatForMe(String chatId, String userId) async {
    await _chatService.deleteChatForMe(chatId, userId);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chatService.deleteMessage(chatId, messageId);
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _chatService.editMessage(chatId, messageId, newText);
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

  Future<void> updateLastSeen(String userId) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .update({'lastSeen': FieldValue.serverTimestamp()});
  }

  Stream<DocumentSnapshot> getOtherUserStatus(String otherUserId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(otherUserId)
        .snapshots();
  }

  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    await _chatService.setTyping(chatId, userId, isTyping);
  }

  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .doc(chatId)
        .snapshots();
  }

  Future<void> addReaction(String chatId, String messageId, String userId, String emoji) async {
    await _chatService.addReaction(chatId, messageId, userId, emoji);
  }

  Future<void> removeReaction(String chatId, String messageId, String userId) async {
    await _chatService.removeReaction(chatId, messageId, userId);
  }

  Future<List<Map<String, dynamic>>> getChatsForUserSimple(String userId) async {
    final donorSnap = await FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .where('donorId', isEqualTo: userId)
        .get();

    final distributorSnap = await FirebaseFirestore.instance
        .collection(AppConstants.collectionChats)
        .where('distributorId', isEqualTo: userId)
        .get();

    final allDocs = [...donorSnap.docs, ...distributorSnap.docs];

    final chats = <Map<String, dynamic>>[];
    for (final doc in allDocs) {
      final data = doc.data();
      final donorId = data['donorId'] as String? ?? '';
      final distributorId = data['distributorId'] as String? ?? '';
      final otherUserId = userId == donorId ? distributorId : donorId;

      final otherUserDoc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(otherUserId)
          .get();
      final otherUserName = otherUserDoc.data()?['name'] as String? ?? '';

      final listingId = data['listingId'] as String? ?? '';
      String listingTitle = '';
      if (listingId.isNotEmpty) {
        final listingDoc = await FirebaseFirestore.instance
            .collection(AppConstants.collectionFoodListings)
            .doc(listingId)
            .get();
        listingTitle = listingDoc.data()?['title'] as String? ?? '';
      }

      chats.add({
        'chatId': doc.id,
        'otherUserName': otherUserName,
        'listingTitle': listingTitle,
      });
    }

    return chats;
  }

  Future<void> forwardMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final forwardedText = '[Forwarded] $text';
    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: forwardedText,
    );

    await _writeChatNotification(
      chatId: chatId,
      senderId: senderId,
      text: forwardedText,
    );
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
