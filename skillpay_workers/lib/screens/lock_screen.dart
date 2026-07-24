import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dashboard_screen.dart';

class LockScreen extends StatefulWidget {
  final bool isFromResume;

  const LockScreen({super.key, this.isFromResume = false});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    // Delay slightly to ensure transition finishes before popping auth dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMsg = '';
    });

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If device doesn't support biometrics, just unlock
        _unlock();
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your wallet',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuthenticate) {
        _unlock();
      } else {
        setState(() {
          _errorMsg = 'Authentication failed or canceled.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
        _isAuthenticating = false;
      });
    }
  }

  void _unlock() {
    if (!mounted) return;
    if (widget.isFromResume) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Color(0xFFFFC107),
            ),
            const SizedBox(height: 24),
            const Text(
              'App Locked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              )
            ] else if (_isAuthenticating) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFFFFC107)),
            ]
          ],
        ),
      ),
    );
  }
}
