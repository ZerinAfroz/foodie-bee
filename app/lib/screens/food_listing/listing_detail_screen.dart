import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_listing_provider.dart';
import '../../config/theme.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  final String viewMode;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.viewMode = 'donor',
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  DocumentSnapshot? _claim;
  DocumentSnapshot? _distributorClaim;
  bool _claiming = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF4CAF50);
      case 'claimed':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'picked_up':
        return const Color(0xFF9C27B0);
      case 'completed':
        return Colors.grey;
      case 'expired':
        return const Color(0xFFF44336);
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDt(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    return DateFormat('MMM d, yyyy  h:mm a').format(dt);
  }

  Future<void> _loadClaim() async {
    final claim = await context
        .read<FoodListingProvider>()
        .getClaimForListing(widget.listingId);
    if (mounted) setState(() => _claim = claim);
  }

  Future<void> _loadDistributorClaim() async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final claim = await context
        .read<FoodListingProvider>()
        .getDistributorClaimForListing(widget.listingId, uid);
    if (mounted) setState(() => _distributorClaim = claim);
  }

  Future<void> _updateStatus(String status) async {
    final provider = context.read<FoodListingProvider>();
    setState(() {});

    try {
      await provider.updateListingStatus(widget.listingId, status);
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmClaim() async {
    if (_claim == null) return;
    await _updateStatus('confirmed');
    await FirebaseFirestore.instance
        .collection('claims')
        .doc(_claim!.id)
        .update({
      'status': 'confirmed',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    _loadClaim();
  }

  Future<void> _rejectClaim() async {
    if (_claim == null) return;
    await FirebaseFirestore.instance
        .collection('claims')
        .doc(_claim!.id)
        .update({
      'status': 'rejected',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
    await _updateStatus('available');
    _loadClaim();
  }

  Future<void> _markCompleted() async {
    await _updateStatus('completed');
    if (_claim != null) {
      await FirebaseFirestore.instance
          .collection('claims')
          .doc(_claim!.id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _markPickedUpByDistributor() async {
    if (_distributorClaim == null) return;
    final provider = context.read<FoodListingProvider>();
    await provider.markPickedUp(
      _distributorClaim!.id,
      widget.listingId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as picked up!')),
    );
  }

  Future<void> _claimListing(String donorId) async {
    setState(() => _claiming = true);
    final provider = context.read<FoodListingProvider>();
    final distributorId = context.read<AuthProvider>().firebaseUser!.uid;

    final success = await provider.claimListing(
      listingId: widget.listingId,
      distributorId: distributorId,
      donorId: donorId,
    );

    if (!mounted) return;
    setState(() => _claiming = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing claimed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing is no longer available'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('foodListings')
            .doc(widget.listingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Listing not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          final donorId = data['donorId'] as String? ?? '';
          final currentUid =
              context.read<AuthProvider>().firebaseUser!.uid;
          final isOwnListing = donorId == currentUid;

          if (status == 'claimed' && _claim == null) _loadClaim();
          if (widget.viewMode == 'distributor' && _distributorClaim == null) {
            final statuses = ['pending', 'confirmed', 'picked_up', 'completed'];
            if (statuses.contains(status)) _loadDistributorClaim();
          }

          final photos = (data['photoURLs'] as List<dynamic>?) ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(
                  label: Text(status.replaceAll('_', ' '),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _statusColor(status),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 16),

                if (photos.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(photos[i] as String,
                            width: 200, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _detailRow('Donor', data['donorName'] as String? ?? ''),
                if (widget.viewMode == 'distributor')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                            width: 120,
                            child: Text('Phone',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13))),
                        Expanded(
                          child: Text(data['donorPhone'] as String? ?? '',
                              style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                _detailRow('Category',
                    (data['category'] as String? ?? '').replaceAll('_', ' ')),
                _detailRow('Quantity',
                    '${data['quantity']} ${data['quantityUnit']}'),
                _detailRow('Prepared at', _formatDt(data['preparedAt'])),
                _detailRow(
                    'Pickup deadline', _formatDt(data['pickupDeadline'])),
                _detailRow('Address', data['address'] as String? ?? ''),

                if ((data['specialNotes'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Special notes',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(data['specialNotes'] as String,
                      style: TextStyle(color: Colors.grey[700])),
                ],

                const SizedBox(height: 24),

                if (_claim != null && widget.viewMode == 'donor') ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Claimant info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 8),
                  _claimantInfo(_claim!.data() as Map<String, dynamic>),
                  const SizedBox(height: 16),
                ],

                if (widget.viewMode == 'donor' && status == 'claimed')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmClaim,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectClaim,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),

                if (widget.viewMode == 'donor' && status == 'picked_up')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _markCompleted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Mark Completed'),
                    ),
                  ),

                if (widget.viewMode == 'donor' && status == 'confirmed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Awaiting pickup by distributor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                  ),

                if (widget.viewMode == 'distributor' &&
                    status == 'available' &&
                    !isOwnListing)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _claiming ? null : () => _claimListing(donorId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _claiming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Claim This Food',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),

                if (widget.viewMode == 'distributor' &&
                    _distributorClaim != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDistributorClaimStatus(),
                  const SizedBox(height: 16),
                ],

                if (widget.viewMode == 'distributor' && isOwnListing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                        'This is your own listing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildDistributorClaimStatus() {
    if (_distributorClaim == null) return const SizedBox.shrink();
    final claimData = _distributorClaim!.data() as Map<String, dynamic>;
    final claimStatus = claimData['status'] as String? ?? '';

    switch (claimStatus) {
      case 'pending':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Awaiting donor confirmation...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        );
      case 'confirmed':
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _markPickedUpByDistributor,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Mark Picked Up',
                style: TextStyle(fontSize: 16)),
          ),
        );
      case 'picked_up':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Awaiting donor to mark completed...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        );
      case 'completed':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Pickup completed',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.green)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _claimantInfo(Map<String, dynamic> claim) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(claim['distributorId'] as String)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Loading claimant info...');
        }
        final user = snapshot.data!.data() as Map<String, dynamic>?;
        final name = user?['name'] as String? ?? 'Unknown';
        final phone = user?['phone'] as String? ?? '';
        final orgType =
            (user?['orgType'] as String? ?? '').replaceAll('_', ' ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', name),
            if (phone.isNotEmpty) _detailRow('Phone', phone),
            if (orgType.isNotEmpty) _detailRow('Organization', orgType),
          ],
        );
      },
    );
  }
}
