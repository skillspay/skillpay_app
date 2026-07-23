// This screen is superseded by OtpVerificationScreen (with OtpPurpose.signup).
// It is kept as a redirect shim so any remaining navigation references
// still compile and work correctly.
import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  const EmailConfirmationScreen({
    super.key,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    // Immediately replace with the real OTP screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            purpose: OtpPurpose.signup,
          ),
        ),
      );
    });

    // Brief loading state while the redirect happens
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFFC107)),
      ),
    );
  }
}
