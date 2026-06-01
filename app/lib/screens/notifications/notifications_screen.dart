import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/error_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_retryKey),
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionNotifications)
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              onRetry: () => setState(() => _retryKey++),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  Future.delayed(const Duration(milliseconds: 600)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                Future.delayed(const Duration(milliseconds: 600)),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: docs.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) =>
                  _NotificationTile(doc: docs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final DocumentSnapshot doc;
  const _NotificationTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isRead = data['isRead'] as bool? ?? false;
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    final listingId = data['listingId'] as String?;

    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
    final timeStr = timestamp != null
        ? DateFormat('MMM d, h:mm a').format(timestamp)
        : '';

    return ListTile(
      leading: _typeIcon(type),
      title: Text(title,
          style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(timeStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ),
        ],
      ),
      trailing: isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.blue, shape: BoxShape.circle),
            ),
      onTap: () {
        if (!isRead) {
          doc.reference.update({'isRead': true});
        }
        if (listingId != null && listingId.isNotEmpty) {
          final viewMode =
              (type == 'claim_received' || type == 'pickup_completed')
                  ? 'donor'
                  : 'distributor';
          Navigator.pushNamed(context, Routes.listingDetail, arguments: {
            'listingId': listingId,
            'viewMode': viewMode,
          });
        }
      },
    );
  }

  Widget _typeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'claim_received':
        icon = Icons.person_add;
        color = Colors.orange;
      case 'claim_confirmed':
        icon = Icons.check_circle;
        color = Colors.green;
      case 'claim_rejected':
        icon = Icons.cancel;
        color = Colors.red;
      case 'pickup_completed':
        icon = Icons.delivery_dining;
        color = Colors.purple;
      case 'pickup_confirmed':
        icon = Icons.celebration;
        color = Colors.green;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
