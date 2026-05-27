import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_listing_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';


class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markPickedUp(String claimId, String listingId) async {
    final provider = context.read<FoodListingProvider>();
    final auth = context.read<AuthProvider>();
    final distributorName =
        auth.userProfile?.get('name') as String? ?? 'A distributor';

    try {
      final listing = await FirebaseFirestore.instance
          .collection(AppConstants.collectionFoodListings)
          .doc(listingId)
          .get();
      final listingData = listing.data();
      final listingTitle = listingData?['title'] as String? ?? '';
      final donorId = listingData?['donorId'] as String? ?? '';

      await provider.markPickedUp(
        claimId: claimId,
        listingId: listingId,
        listingTitle: listingTitle,
        donorId: donorId,
        distributorName: distributorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as picked up!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Color _claimStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'picked_up':
        return const Color(0xFF9C27B0);
      case 'completed':
        return Colors.grey;
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final distributorId = context.read<AuthProvider>().firebaseUser!.uid;
    final provider = context.watch<FoodListingProvider>();
    final claims = provider.getDistributorClaims(distributorId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Claims'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: claims,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allClaims = snapshot.data?.docs ?? [];

          final active = allClaims.where((d) {
            final s = d['status'] as String? ?? '';
            return s == 'pending' || s == 'confirmed';
          }).toList();

          final completed = allClaims.where((d) {
            final s = d['status'] as String? ?? '';
            return s == 'picked_up' || s == 'completed';
          }).toList();

          final rejected = allClaims.where((d) {
            final s = d['status'] as String? ?? '';
            return s == 'rejected';
          }).toList();

          final tabs = [active, completed, rejected];

          return TabBarView(
            controller: _tabController,
            children: tabs.map((docs) {
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No claims here yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final claim = docs[index];
                  final claimData = claim.data() as Map<String, dynamic>;
                  final claimStatus = claimData['status'] as String? ?? '';
                  final listingId = claimData['listingId'] as String? ?? '';

                  return _ClaimCard(
                    claimId: claim.id,
                    listingId: listingId,
                    claimStatus: claimStatus,
                    claimStatusColor: _claimStatusColor(claimStatus),
                    onMarkPickedUp: claimStatus == 'confirmed'
                        ? () => _markPickedUp(claim.id, listingId)
                        : null,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final String claimId;
  final String listingId;
  final String claimStatus;
  final Color claimStatusColor;
  final VoidCallback? onMarkPickedUp;

  const _ClaimCard({
    required this.claimId,
    required this.listingId,
    required this.claimStatus,
    required this.claimStatusColor,
    this.onMarkPickedUp,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionFoodListings)
          .doc(listingId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final title = data?['title'] as String? ?? 'Unknown listing';
        final donorName = data?['donorName'] as String? ?? '';
        final photos = (data?['photoURLs'] as List<dynamic>?) ?? [];

        return Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/listing-detail',
                arguments: {
                  'listingId': listingId,
                  'viewMode': 'distributor',
                }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (photos.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(photos.first as String,
                          width: 64, height: 64, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (donorName.isNotEmpty)
                          Text(donorName,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(claimStatus.replaceAll('_', ' '),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: claimStatusColor,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  if (onMarkPickedUp != null)
                    TextButton(
                      onPressed: onMarkPickedUp,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      child: const Text('Mark\nPicked Up',
                          textAlign: TextAlign.center),
                    )
                  else if (claimStatus == 'pending')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('Awaiting\nconfirmation...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
