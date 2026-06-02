import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_listing_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../profile/map_picker_screen.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  String? _category;
  String _quantityUnit = 'kg';
  DateTime? _preparedAt;
  DateTime? _pickupDeadline;
  LatLng? _location;

  static const _categories = AppConstants.foodTypes;
  static const _quantityUnits = AppConstants.quantityUnits;

  @override
  void initState() {
    super.initState();
    _preparedAt = DateTime.now();
    _initFromProfile();
  }

  void _initFromProfile() {
    final profile = context.read<AuthProvider>().userProfile;
    if (profile != null && profile.exists) {
      final data = profile.data() as Map<String, dynamic>;
      if (data['address'] != null) {
        _addressController.text = data['address'] as String;
      }
      if (data['location'] != null) {
        final geo = data['location'] as GeoPoint;
        _location = LatLng(geo.latitude, geo.longitude);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) return;
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _selectedImages.add(file));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _pickLocation() async {
    final loc = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (loc != null) setState(() => _location = loc);
  }

  Future<void> _pickDateTime({required DateTime? current, required ValueChanged<DateTime> onPicked}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: current != null ? TimeOfDay.fromDateTime(current) : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
    setState(() {});
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy  h:mm a').format(dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      _showError('Please select a category');
      return;
    }
    if (_location == null) {
      _showError('Please pin the pickup location on the map');
      return;
    }
    if (_pickupDeadline == null) {
      _showError('Please set a pickup deadline');
      return;
    }
    if (_pickupDeadline!.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      _showError('Pickup deadline must be at least 30 minutes from now');
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<FoodListingProvider>();
    final donorId = auth.firebaseUser!.uid;
    final profile = auth.userProfile?.data() as Map<String, dynamic>?;

    final data = <String, dynamic>{
      'donorId': donorId,
      'donorName': profile?['name'] ?? '',
      'donorPhone': auth.firebaseUser!.phoneNumber ?? '',
      'title': _titleController.text.trim(),
      'category': _category,
      'quantity': double.tryParse(_quantityController.text.trim()) ?? 0,
      'quantityUnit': _quantityUnit,
      'preparedAt': _preparedAt ?? DateTime.now(),
      'pickupDeadline': _pickupDeadline,
      'location': GeoFirePoint(
              GeoPoint(_location!.latitude, _location!.longitude)).data,
      'address': _addressController.text.trim(),
      'specialNotes': _notesController.text.trim(),
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final imagePaths = _selectedImages.map((f) => f.path).toList();

    try {
      await provider.postListing(imagePaths: imagePaths, listingData: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food listing posted!')),
      );
      Navigator.pushReplacementNamed(context, Routes.myListings);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to post listing. Try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodListingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Post Food Listing')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppConstants.defaultPadding,
          right: AppConstants.defaultPadding,
          top: AppConstants.defaultPadding,
          bottom: MediaQuery.of(context).viewPadding.bottom + AppConstants.defaultPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your surplus food',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Food title',
                  hintText: 'e.g. Chicken Biryani - 5kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 3 ? 'Title is required (3+ chars)' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _quantityUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _quantityUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _quantityUnit = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Photos
              Text('Photos (up to 3)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + (_selectedImages.length < 3 ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey, size: 28),
                              SizedBox(height: 4),
                              Text('Add', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:                           Image.file(
                            File(_selectedImages[index].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Prepared at
              Text('Prepared at', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pickDateTime(
                  current: _preparedAt,
                  onPicked: (dt) => _preparedAt = dt,
                ),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _preparedAt != null ? _formatDateTime(_preparedAt) : 'Set date & time',
                ),
              ),
              const SizedBox(height: 24),

              // Pickup deadline
              Text('Pickup deadline', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pickDateTime(
                  current: _pickupDeadline,
                  onPicked: (dt) => _pickupDeadline = dt,
                ),
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(
                  _pickupDeadline != null ? _formatDateTime(_pickupDeadline) : 'Set deadline (30+ min from now)',
                ),
              ),
              const SizedBox(height: 24),

              // Location
              Text('Pickup location', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: Icon(
                  Icons.location_on,
                  color: _location != null ? AppTheme.primaryColor : Colors.grey,
                ),
                label: Text(
                  _location != null
                      ? 'Location set (${_location!.latitude.toStringAsFixed(3)}, ${_location!.longitude.toStringAsFixed(3)})'
                      : 'Pin location on map',
                ),
              ),
              const SizedBox(height: 24),

              // Special notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Special notes (optional)',
                  hintText: 'e.g. Needs cold storage, Vegetarian only',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Text(AppConstants.btnPostListing, style: TextStyle(fontSize: 16)),
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
