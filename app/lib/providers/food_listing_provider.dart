import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../config/constants.dart';

class FoodListingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  Future<void> postListing({
    required List<String> imagePaths,
    required Map<String, dynamic> listingData,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final urls = <String>[];
      for (final path in imagePaths) {
        final url = await StorageService.uploadFoodImage(path);
        urls.add(url);
      }

      listingData['photoURLs'] = urls;

      await _firestore
          .collection(AppConstants.collectionFoodListings)
          .add(listingData);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> getDonorListings(String donorId) {
    return _firestore
        .collection(AppConstants.collectionFoodListings)
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateListingStatus(String listingId, String status) async {
    await _firestore
        .collection(AppConstants.collectionFoodListings)
        .doc(listingId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot?> getClaimForListing(String listingId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionClaims)
        .where('listingId', isEqualTo: listingId)
        .where('status', whereIn: ['pending', 'confirmed', 'picked_up'])
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }
}
