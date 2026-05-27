import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_listing_provider.dart';
import '../../config/theme.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key});

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen> {
  final _mapController = MapController();
  static const _defaultCenter = LatLng(23.8103, 90.4125);
  LatLng _currentLocation = _defaultCenter;
  double _radiusKm = 5;
  bool _locationReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final profile = context.read<AuthProvider>().userProfile;
      if (profile != null && profile.exists) {
        final data = profile.data() as Map<String, dynamic>;
        final loc = data['location'];
        if (loc is GeoPoint) {
          _currentLocation = LatLng(loc.latitude, loc.longitude);
        }
        if (data['pickupRadius'] != null) {
          _radiusKm = (data['pickupRadius'] as num).toDouble();
        }
      }
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      _currentLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    if (mounted) {
      setState(() => _locationReady = true);
      _mapController.move(_currentLocation, 13);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final loc = LatLng(pos.latitude, pos.longitude);
      _currentLocation = loc;
      _mapController.move(loc, 15);
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location')),
      );
    }
  }

  LatLng _locationFromData(Map<String, dynamic> data) {
    final loc = data['location'];
    if (loc is GeoPoint) return LatLng(loc.latitude, loc.longitude);
    if (loc is Map) {
      final gp = loc['geopoint'];
      if (gp is GeoPoint) return LatLng(gp.latitude, gp.longitude);
    }
    return _defaultCenter;
  }

  void _showListingSheet(Map<String, dynamic> data, String listingId,
      double distanceKm) {
    final photos = (data['photoURLs'] as List<dynamic>?) ?? [];
    final title = data['title'] as String? ?? '';
    final category = (data['category'] as String? ?? '').replaceAll('_', ' ');
    final qty = data['quantity'] ?? 0;
    final unit = data['quantityUnit'] as String? ?? '';
    final donorName = data['donorName'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(photos.first as String,
                    height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            if (photos.isNotEmpty) const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$category · $qty $unit',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(donorName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                Icon(Icons.near_me, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text('${distanceKm.toStringAsFixed(1)} km',
                    style:
                        TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/listing-detail',
                      arguments: {
                        'listingId': listingId,
                        'viewMode': 'distributor',
                      });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodListingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Find Food')),
      body: _locationReady
          ? StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
              stream: provider.getNearbyListings(
                center:
                    GeoPoint(_currentLocation.latitude, _currentLocation.longitude),
                radiusKm: _radiusKm,
              ),
              builder: (context, snapshot) {
                final listings = snapshot.data ?? [];

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.foodiebee.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation,
                              child: const Icon(Icons.my_location,
                                  color: Colors.blue, size: 32),
                            ),
                            ...listings.where((doc) => doc.data() != null).map((doc) {
                              final data = doc.data()!;
                              final pos = _locationFromData(data);
                              final distanceKm =
                                  const Distance().as(LengthUnit.Kilometer,
                                      _currentLocation, pos);

                              return Marker(
                                point: pos,
                                child: GestureDetector(
                                  onTap: () => _showListingSheet(
                                      data, doc.id, distanceKm),
                                  child: const Icon(Icons.restaurant,
                                      color: Colors.red, size: 36),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 16,
                      bottom: 100,
                      child: FloatingActionButton(
                        heroTag: 'myLocation',
                        mini: true,
                        onPressed: _goToCurrentLocation,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator()),
                    if (snapshot.hasError)
                      Center(
                        child: Text('Could not load listings',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                    if (snapshot.hasData && listings.isEmpty)
                      Center(
                        child: Text(
                          'No food available near you.\nTry expanding your pickup radius.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 15),
                        ),
                      ),
                  ],
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
