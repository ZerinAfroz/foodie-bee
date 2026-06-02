import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String verificationId;

  const OTPScreen({
    required this.phone,
    required this.verificationId,
    super.key,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  int _resendSeconds = 30;
  Timer? _timer;
  String? _error;
  bool _canResend = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;

    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    _controllers.last.addListener(_onLastFieldChanged);
    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_onLastFieldChanged);
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  void _onLastFieldChanged() {
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyOTP();
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verifyOTP() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOTP(
      _verificationId,
      _otpCode,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.hasProfile) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          authProvider.role == 'donor'
              ? Routes.donorHome
              : Routes.distributorHome,
          (_) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, Routes.roleSelection, (_) => false);
      }
    } else {
      setState(() => _error = 'Invalid code. Please try again.');
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    final e164Phone = '+880${widget.phone.substring(1)}';
    try {
      final authProvider = context.read<AuthProvider>();
      final verificationId = await authProvider.sendOTP(e164Phone);
      _verificationId = verificationId;
      _startResendTimer();
      setState(() => _error = null);
    } on FirebaseAuthException catch (e) {
      setState(
        () => _error = e.message ?? 'Failed to resend code. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Verify Phone',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code sent to +880${widget.phone.substring(1)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  const minBox = 40.0;
                  const maxBox = 56.0;
                  final box = ((constraints.maxWidth - 5 * spacing) / 6)
                      .clamp(minBox, maxBox);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final borderColor = _error != null
                          ? AppTheme.errorColor
                          : Colors.grey[300]!;
                      return SizedBox(
                        width: box,
                        height: 64,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (_error != null) setState(() => _error = null);
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ||
                          _otpCode.length != 6
                      ? null
                      : _verifyOTP,
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
                      : const Text(AppConstants.btnVerify, style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _canResend
                          ? "Didn't receive the code? "
                          : 'Resend code in ${_resendSeconds}s',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (_canResend)
                      GestureDetector(
                        onTap: _resendOTP,
                        child: const Text(
                          AppConstants.btnResend,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Change phone number',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
