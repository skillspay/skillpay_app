import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';

enum OtpPurpose { signup, passwordReset }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.passwordReset,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isFormValid = false;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canResend = true;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_validateForm);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _validateForm() {
    final valid = _controllers.every((c) => c.text.isNotEmpty);
    if (valid != _isFormValid) setState(() => _isFormValid = valid);
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _handleResend() async {
    _startResendTimer();
    try {
      if (widget.purpose == OtpPurpose.signup) {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: widget.email,
        );
      } else {
        await _authService.sendPasswordResetEmail(widget.email);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code resent — check your email'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleContinue() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpType = widget.purpose == OtpPurpose.signup
          ? OtpType.signup
          : OtpType.recovery;

      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otp,
        type: otpType,
      );

      if (response.session == null) {
        throw Exception('Verification failed. Please try again.');
      }

      if (!mounted) return;

      if (widget.purpose == OtpPurpose.signup) {
        // Email confirmed — sign in is now active, sync NestJS user row
        final user = response.user;
        if (user != null) {
          try {
            final authService = AuthService();
            // Trigger NestJS register sync now that we have a session
            await authService.syncUserAfterVerification(
              email: user.email ?? widget.email,
              fullName: user.userMetadata?['full_name']?.toString() ?? '',
              phone: user.userMetadata?['phone']?.toString() ?? '',
              role: user.userMetadata?['role']?.toString() ?? 'ARTISAN',
            );
          } catch (_) {
            // Non-fatal — will retry on next signIn
          }
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        // Password reset — go to new password screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.purpose == OtpPurpose.signup
        ? 'Confirm Email'
        : 'Forgot Password';
    final subtitle = widget.purpose == OtpPurpose.signup
        ? 'Enter the 6-digit code sent to\n${widget.email}'
        : 'Enter OTP code sent to your email';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.handyman,
                        size: 60,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // OTP Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? Colors.red.shade300
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFFFC107), width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (value.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_errorMessage!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ),

                // Resend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_canResend) ...[
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text('Code sent – ${_formatTime(_secondsRemaining)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ] else ...[
                      const Text("Didn't get the code? ",
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13)),
                      GestureDetector(
                        onTap: _handleResend,
                        child: const Text('Resend',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isFormValid && !_isLoading)
                        ? _handleContinue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFFDE69F),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFFFDE69F),
                      disabledForegroundColor: Colors.black54,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black)),
                          )
                        : const Text('Continue',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
