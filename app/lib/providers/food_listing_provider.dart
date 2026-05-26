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
}
