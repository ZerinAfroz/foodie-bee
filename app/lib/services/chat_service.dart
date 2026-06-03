import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> findOrCreateChat({
    required String listingId,
    required String donorId,
    required String distributorId,
  }) async {
    final existing = await _firestore
        .collection(AppConstants.collectionChats)
        .where('listingId', isEqualTo: listingId)
        .where('donorId', isEqualTo: donorId)
        .where('distributorId', isEqualTo: distributorId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await _firestore.collection(AppConstants.collectionChats).add({
      'listingId': listingId,
      'donorId': donorId,
      'distributorId': distributorId,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final chatDoc = await _firestore
        .collection(AppConstants.collectionChats)
        .doc(chatId)
        .get();
    final chatData = chatDoc.data();
    if (chatData == null) return;

    final donorId = chatData['donorId'] as String? ?? '';
    final distributorId = chatData['distributorId'] as String? ?? '';
    final recipientId = senderId == donorId ? distributorId : donorId;

    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection(AppConstants.collectionChats)
        .doc(chatId)
        .collection(AppConstants.collectionMessages)
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final chatRef =
        _firestore.collection(AppConstants.collectionChats).doc(chatId);

    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadBy': FieldValue.arrayUnion([recipientId]),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getChatsForUser(String userId) {
    return _firestore
        .collection(AppConstants.collectionChats)
        .where('donorId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatsForUserAsDistributor(String userId) {
    return _firestore
        .collection(AppConstants.collectionChats)
        .where('distributorId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection(AppConstants.collectionChats)
        .doc(chatId)
        .collection(AppConstants.collectionMessages)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String chatId, String userId) async {
    final chatRef =
        _firestore.collection(AppConstants.collectionChats).doc(chatId);

    final chatDoc = await chatRef.get();
    final data = chatDoc.data();
    if (data == null) return;

    final unreadBy = List<String>.from(data['unreadBy'] as List<dynamic>? ?? []);
    if (unreadBy.contains(userId)) {
      await chatRef.update({
        'unreadBy': FieldValue.arrayRemove([userId]),
      });
    }

    final unreadMessages = await _firestore
        .collection(AppConstants.collectionChats)
        .doc(chatId)
        .collection(AppConstants.collectionMessages)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (unreadMessages.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<int> unreadChatCount(String userId) async {
    final donorChats = await _firestore
        .collection(AppConstants.collectionChats)
        .where('donorId', isEqualTo: userId)
        .where('unreadBy', arrayContains: userId)
        .get();

    final distributorChats = await _firestore
        .collection(AppConstants.collectionChats)
        .where('distributorId', isEqualTo: userId)
        .where('unreadBy', arrayContains: userId)
        .get();

    return donorChats.docs.length + distributorChats.docs.length;
  }

  Stream<int> unreadChatCountStream(String userId) async* {
    final donorQuery = _firestore
        .collection(AppConstants.collectionChats)
        .where('donorId', isEqualTo: userId)
        .where('unreadBy', arrayContains: userId);

    final distributorQuery = _firestore
        .collection(AppConstants.collectionChats)
        .where('distributorId', isEqualTo: userId)
        .where('unreadBy', arrayContains: userId);

    await for (final _ in donorQuery.snapshots()) {
      final donorSnap = await donorQuery.get();
      final distSnap = await distributorQuery.get();
      yield donorSnap.docs.length + distSnap.docs.length;
    }
  }
}
