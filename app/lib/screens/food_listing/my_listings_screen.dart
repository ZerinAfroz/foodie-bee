import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_listing_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
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

  bool _isActive(String status) =>
      ['available', 'claimed', 'confirmed'].contains(status);
  bool _isCompleted(String status) =>
      ['picked_up', 'completed'].contains(status);
  bool _isExpired(String status) =>
      ['expired', 'cancelled'].contains(status);

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

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final donorId = context.read<AuthProvider>().firebaseUser!.uid;
    final provider = context.watch<FoodListingProvider>();
    final listings = provider.getDonorListings(donorId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: listings,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          final active = allDocs.where((d) {
            final s = d['status'] as String? ?? '';
            return _isActive(s);
          }).toList();

          final completed = allDocs.where((d) {
            final s = d['status'] as String? ?? '';
            return _isCompleted(s);
          }).toList();

          final expired = allDocs.where((d) {
            final s = d['status'] as String? ?? '';
            return _isExpired(s);
          }).toList();

          final tabs = [active, completed, expired];

          return TabBarView(
            controller: _tabController,
            children: tabs.map((docs) {
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No listings yet',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/post-listing'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Post your first listing'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _ListingCard(
                    data: data,
                    statusColor: _statusColor(data['status'] ?? ''),
                    statusLabel: _statusLabel(data['status'] ?? ''),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/listing-detail',
                      arguments: {'listingId': doc.id, 'viewMode': 'donor'},
                    ),
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

class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _ListingCard({
    required this.data,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  String _timeLeft(dynamic deadline) {
    if (deadline == null) return '';
    final dt = (deadline as Timestamp).toDate();
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h left';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    return '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final photos = (data['photoURLs'] as List<dynamic>?) ?? [];
    final title = data['title'] as String? ?? '';
    final qty = data['quantity'] ?? 0;
    final unit = data['quantityUnit'] as String? ?? '';
    final deadline = data['pickupDeadline'];

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (photos.isNotEmpty)
              Image.network(
                photos.first as String,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              )
            else
              Container(
                width: 90,
                height: 90,
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('$qty $unit',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(_timeLeft(data['pickupDeadline']),
                        style: TextStyle(
                            color: deadline != null &&
                                    (deadline as Timestamp)
                                            .toDate()
                                            .difference(DateTime.now())
                                            .inMinutes <
                                        60
                                ? AppTheme.errorColor
                                : Colors.grey[600],
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: statusColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
