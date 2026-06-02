import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import 'map_picker_screen.dart';

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _businessType;
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  TimeOfDay? _pickupStart;
  TimeOfDay? _pickupEnd;
  LatLng? _location;

  static const _businessTypes = AppConstants.businessTypes;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final loc = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (loc != null) setState(() => _location = loc);
  }

  Future<void> _pickTime({
    required TimeOfDay? current,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final time = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) onPicked(time);
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_businessType == null) {
      _showError('Please select a business type');
      return;
    }
    if (_location == null) {
      _showError('Please pin your location on the map');
      return;
    }
    if (_openTime == null || _closeTime == null) {
      _showError('Please set your operating hours');
      return;
    }

    final data = <String, dynamic>{
      'role': 'donor',
      'name': _nameController.text.trim(),
      'businessType': _businessType,
      'address': _addressController.text.trim(),
      'location': GeoPoint(_location!.latitude, _location!.longitude),
      'operatingHours':
          '${_openTime!.format(context)} - ${_closeTime!.format(context)}',
      if (_pickupStart != null && _pickupEnd != null)
        'preferredPickupWindow':
            '${_pickupStart!.format(context)} - ${_pickupEnd!.format(context)}',
    };

    await context.read<AuthProvider>().createProfile(data);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.donorHome, (_) => false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Donor Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your business',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Business name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Required, 2+ chars' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                decoration: InputDecoration(
                  labelText: 'Business type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _businessTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _businessType = v),
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Address is required'
                    : null,
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
              Text('Operating hours',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Open',
                      time: _openTime,
                      onTap: () => _pickTime(
                        current: _openTime,
                        onPicked: (t) => _openTime = t,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Close',
                      time: _closeTime,
                      onTap: () => _pickTime(
                        current: _closeTime,
                        onPicked: (t) => _closeTime = t,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Preferred pickup window (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'From',
                      time: _pickupStart,
                      onTap: () => _pickTime(
                        current: _pickupStart,
                        onPicked: (t) => _pickupStart = t,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'To',
                      time: _pickupEnd,
                      onTap: () => _pickTime(
                        current: _pickupEnd,
                        onPicked: (t) => _pickupEnd = t,
                      ),
                    ),
                  ),
                ],
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

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        time != null ? time!.format(context) : label,
        style: TextStyle(
          fontSize: 15,
          color: time != null ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}
