import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'jobs_tab.dart';
import 'history_tab.dart';
import 'messages_tab.dart';
import 'settings_tab.dart';
import 'package:skillpay/screens/worker_onboarding_screen.dart';
import '../services/artisan_profile_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static bool _hasShownProfileSetup = false;
  int _currentIndex = 0;
  bool _needsProfileSetup = false;
  bool _hasPhotoStatus = false;
  bool _hasBioStatus = false;
  bool _isVerified = false;
  bool _isLoading = true;
  String? _profilePhotoUrl;

  final _profileService = ArtisanProfileService();

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final profile = await _profileService.fetchProfile();
      if (profile != null) {
        final verificationStatus =
            profile['verificationStatus']?.toString() ??
            profile['verification_status']?.toString() ??
            'UNVERIFIED';
        _isVerified = verificationStatus == 'VERIFIED';
        _profilePhotoUrl = profile['profilePhoto']?.toString() ?? profile['profile_photo']?.toString();

        // Show setup modal if profile photo or bio is missing
        final hasPhoto = _profilePhotoUrl != null;
        final hasBio = (profile['bio']?.toString() ?? '').isNotEmpty;
        _needsProfileSetup = !hasPhoto || !hasBio;
        _hasPhotoStatus = hasPhoto;
        _hasBioStatus = hasBio;
      } else {
        _needsProfileSetup = true;
      }
    } catch (_) {
      // Non-fatal — proceed without profile data
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _tabs = [
            HomeTab(isVerified: _isVerified, profilePhotoUrl: _profilePhotoUrl),
            const JobsTab(),
            const HistoryTab(),
            const MessagesTab(),
            const SettingsTab(),
          ];
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_needsProfileSetup && !_hasShownProfileSetup && mounted) {
            _hasShownProfileSetup = true;
            _showProfileSetupModal();
          }
        });
      }
    }
  }

  void _showProfileSetupModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WorkerOnboardingScreen(),
      ),
    ).then((_) {
      // Re-fetch profile logic here if necessary, or just rely on state
      _fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _tabs[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                activeIcon: Icon(Icons.mail),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
