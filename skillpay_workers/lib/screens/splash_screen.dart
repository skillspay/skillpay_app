import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Show splash screen for a briefly
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Listen to auth state to correctly handle delayed session recovery from local storage
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      
      final session = data.session;
      
      // If we got a session, go to Dashboard
      if (session != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // Only redirect to Onboarding if we are sure there's no session
        if (data.event == AuthChangeEvent.initialSession || data.event == AuthChangeEvent.signedOut) {
          // Check if it's the very first time opening the app
          final prefs = await SharedPreferences.getInstance();
          final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
          
          if (hasSeenOnboarding) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 200,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.construction,
            size: 100,
            color: Colors.amber,
          ),
        ),
      ),
    );
  }
}
