import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
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

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> getNearbyListings({
    required GeoPoint center,
    required double radiusKm,
  }) {
    final ref = _firestore
        .collection(AppConstants.collectionFoodListings)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data()!,
          toFirestore: (d, _) => d,
        );

    final geoRef = GeoCollectionReference<Map<String, dynamic>>(ref);

    return geoRef.subscribeWithin(
      center: GeoFirePoint(center),
      radiusInKm: radiusKm,
      field: 'location',
      geopointFrom: (data) {
        final loc = data['location'];
        if (loc is GeoPoint) return loc;
        if (loc is Map) return (loc['geopoint'] as GeoPoint?) ?? const GeoPoint(0, 0);
        return const GeoPoint(0, 0);
      },
      queryBuilder: (query) => query.where('status', isEqualTo: 'available'),
      strictMode: true,
    );
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

  Future<bool> claimListing({
    required String listingId,
    required String distributorId,
    required String donorId,
    required String listingTitle,
    required String distributorName,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final listingRef =
            _firestore.collection(AppConstants.collectionFoodListings).doc(listingId);
        final listing = await transaction.get(listingRef);
        if (!listing.exists || listing['status'] != 'available') {
          throw Exception('Listing is no longer available');
        }

        transaction.update(listingRef, {
          'status': 'claimed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final claimRef =
            _firestore.collection(AppConstants.collectionClaims).doc();
        transaction.set(claimRef, {
          'listingId': listingId,
          'donorId': donorId,
          'distributorId': distributorId,
          'status': 'pending',
          'claimedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      await _writeNotification(
        userId: donorId,
        title: 'New Claim',
        body: '$distributorName wants to pick up $listingTitle',
        type: 'claim_received',
        listingId: listingId,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<QuerySnapshot> getDistributorClaims(String distributorId) {
    return _firestore
        .collection(AppConstants.collectionClaims)
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markPickedUp({
    required String claimId,
    required String listingId,
    required String listingTitle,
    required String donorId,
    required String distributorName,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final listingRef =
          _firestore.collection(AppConstants.collectionFoodListings).doc(listingId);
      transaction.update(listingRef, {
        'status': 'picked_up',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final claimDocRef =
          _firestore.collection(AppConstants.collectionClaims).doc(claimId);
      transaction.update(claimDocRef, {
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _writeNotification(
      userId: donorId,
      title: 'Food Picked Up',
      body: '$distributorName has picked up $listingTitle. Confirm completion.',
      type: 'pickup_completed',
      listingId: listingId,
      claimId: claimId,
    );
  }

  Future<void> confirmClaim({
    required String claimId,
    required String listingId,
    required String listingTitle,
    required String donorPhone,
    required String distributorId,
  }) async {
    await updateListingStatus(listingId, 'confirmed');

    await _firestore
        .collection(AppConstants.collectionClaims)
        .doc(claimId)
        .update({
      'status': 'confirmed',
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _writeNotification(
      userId: distributorId,
      title: 'Claim Confirmed',
      body:
          'Your claim for $listingTitle has been confirmed. Contact donor at $donorPhone',
      type: 'claim_confirmed',
      listingId: listingId,
      claimId: claimId,
    );
  }

  Future<void> rejectClaim({
    required String claimId,
    required String listingId,
    required String listingTitle,
    required String distributorId,
  }) async {
    await updateListingStatus(listingId, 'available');

    await _firestore
        .collection(AppConstants.collectionClaims)
        .doc(claimId)
        .update({
      'status': 'rejected',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _writeNotification(
      userId: distributorId,
      title: 'Claim Rejected',
      body: 'Your claim for $listingTitle was not accepted',
      type: 'claim_rejected',
      listingId: listingId,
      claimId: claimId,
    );
  }

  Future<void> completePickup({
    required String claimId,
    required String listingId,
    required String listingTitle,
    required String distributorId,
  }) async {
    await updateListingStatus(listingId, 'completed');

    await _firestore
        .collection(AppConstants.collectionClaims)
        .doc(claimId)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _writeNotification(
      userId: distributorId,
      title: 'Pickup Complete',
      body: 'Pickup for $listingTitle is complete. Thank you!',
      type: 'pickup_confirmed',
      listingId: listingId,
      claimId: claimId,
    );
  }

  Future<DocumentSnapshot?> getDistributorClaimForListing(
      String listingId, String distributorId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionClaims)
        .where('listingId', isEqualTo: listingId)
        .where('distributorId', isEqualTo: distributorId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  Future<void> _writeNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? listingId,
    String? claimId,
  }) async {
    await _firestore.collection(AppConstants.collectionNotifications).add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'listingId': listingId ?? '',
      'claimId': claimId ?? '',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
