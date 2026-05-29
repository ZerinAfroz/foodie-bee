import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.userProfile;
    final data = profile?.data() as Map<String, dynamic>? ?? {};
    final role = data['role'] as String? ?? '';
    final name = data['name'] as String? ?? 'Unknown';
    final phone = auth.firebaseUser?.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 32, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Chip(
                label: Text(role.toUpperCase()),
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            _infoRow(Icons.phone, 'Phone',
                phone.isNotEmpty ? phone : 'Not set'),
            _infoRow(Icons.location_on, 'Address',
                data['address'] as String? ?? 'Not set'),
            const Divider(height: 32),
            if (role == 'donor') ...[
              _infoRow(
                  Icons.business,
                  'Business Type',
                  (data['businessType'] as String? ?? '')
                      .replaceAll('_', ' ')
                      .replaceAll(' ', ' ')..trim(),
                  ),
              _infoRow(Icons.access_time, 'Operating Hours',
                  data['operatingHours'] as String? ?? 'Not set'),
              if (data['preferredPickupWindow'] != null)
                _infoRow(Icons.schedule, 'Preferred Pickup',
                    data['preferredPickupWindow'] as String),
            ],
            if (role == 'distributor') ...[
              _infoRow(
                  Icons.business,
                  'Organization Type',
                  (data['orgType'] as String? ?? '')
                      .replaceAll('_', ' ')),
              _infoRow(
                  Icons.people,
                  'People Served Daily',
                  '${data['peopleServed'] ?? 0}'),
              _infoRow(Icons.near_me, 'Pickup Radius',
                  '${data['pickupRadius'] ?? 5} km'),
              if (data['preferredFoodTypes'] != null) ...[
                const SizedBox(height: 8),
                const Text('Preferred food types',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      (data['preferredFoodTypes'] as List<dynamic>?)
                              ?.map((t) => Chip(
                                    label: Text(
                                        t.toString().replaceAll('_', ' ')),
                                    visualDensity:
                                        VisualDensity.compact,
                                  ))
                              .toList() ??
                          [],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value.isNotEmpty ? value : 'Not set',
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
