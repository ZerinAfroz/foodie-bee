import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'otp_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidBDPhone(String phone) {
    return RegExp(AppConstants.bdPhoneRegex).hasMatch(phone);
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (!_isValidBDPhone(phone)) {
      setState(
        () => _error = 'Enter a valid 11-digit BD number (01XXXXXXXXX)',
      );
      return;
    }

    final e164Phone = '+880${phone.substring(1)}';
    setState(() => _error = null);

    try {
      final authProvider = context.read<AuthProvider>();
      final verificationId = await authProvider.sendOTP(e164Phone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            phone: phone,
            verificationId: verificationId,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e.message));
    }
  }

  String _mapAuthError(String? message) {
    if (message == null) return 'Something went wrong. Try again.';
    if (message.contains('too many')) {
      return 'Too many attempts. Try again later.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your phone number to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              Form(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                      ),
                      child: const Text(
                        '+880',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        decoration: InputDecoration(
                          hintText: '01XXXXXXXXX',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultRadius,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultRadius,
                      ),
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
                      : const Text('Send OTP', style: TextStyle(fontSize: 16)),
                ),
              ),
              const Spacer(flex: 2),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
