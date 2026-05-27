import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import 'map_picker_screen.dart';

class DistributorProfileScreen extends StatefulWidget {
  const DistributorProfileScreen({super.key});

  @override
  State<DistributorProfileScreen> createState() =>
      _DistributorProfileScreenState();
}

class _DistributorProfileScreenState extends State<DistributorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _peopleController = TextEditingController();
  String? _orgType;
  bool _hasVehicle = false;
  double _pickupRadius = 5;
  LatLng? _location;
  final Set<String> _preferredFoodTypes = {};

  static const _orgTypes = [
    'orphanage',
    'shelter',
    'madrasa',
    'mosque',
    'community_kitchen',
    'ngo',
    'other',
  ];

  static const _foodTypes = [
    'cooked',
    'raw',
    'packaged',
    'bakery',
    'fruits_veg',
    'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final loc = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (loc != null) setState(() => _location = loc);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_orgType == null) {
      _showError('Please select an organization type');
      return;
    }
    if (_location == null) {
      _showError('Please pin your location on the map');
      return;
    }

    final data = <String, dynamic>{
      'role': 'distributor',
      'name': _nameController.text.trim(),
      'orgType': _orgType,
      'address': _addressController.text.trim(),
      'location': GeoPoint(_location!.latitude, _location!.longitude),
      'peopleServed': int.tryParse(_peopleController.text.trim()) ?? 0,
      'hasVehicle': _hasVehicle,
      'pickupRadius': _pickupRadius.toInt(),
      'preferredFoodTypes': _preferredFoodTypes.toList(),
    };

    await context.read<AuthProvider>().createProfile(data);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.distributorHome);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  void _toggleFoodType(String type) {
    setState(() {
      if (_preferredFoodTypes.contains(type)) {
        _preferredFoodTypes.remove(type);
      } else {
        _preferredFoodTypes.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Distributor Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your organization',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Organization name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Required, 2+ chars' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _orgType,
                decoration: InputDecoration(
                  labelText: 'Organization type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _orgTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _orgType = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: Icon(
                  Icons.location_on,
                  color: _location != null
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
                label: Text(
                  _location != null
                      ? 'Location set (${_location!.latitude.toStringAsFixed(3)}, ${_location!.longitude.toStringAsFixed(3)})'
                      : 'Pin your location on map',
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _peopleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'People served daily',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Must be 1 or more';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Can you pick up food?',
                      style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  Switch(
                    value: _hasVehicle,
                    onChanged: (v) => setState(() => _hasVehicle = v),
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Pickup radius: ${_pickupRadius.toInt()} km',
                  style: const TextStyle(fontSize: 15)),
              Slider(
                value: _pickupRadius,
                min: 1,
                max: 20,
                divisions: 19,
                label: '${_pickupRadius.toInt()} km',
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _pickupRadius = v),
              ),
              const SizedBox(height: 16),
              Text('Preferred food types (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _foodTypes.map((type) {
                  final selected = _preferredFoodTypes.contains(type);
                  return FilterChip(
                    label: Text(type.replaceAll('_', ' ')),
                    selected: selected,
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    onSelected: (_) => _toggleFoodType(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Profile',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
