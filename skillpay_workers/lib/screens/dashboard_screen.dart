import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'jobs_tab.dart';
import 'history_tab.dart';
import 'messages_tab.dart';
import 'settings_tab.dart';
import 'package:skillpay_workers/screens/worker_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_needsProfileSetup && !_hasShownProfileSetup && mounted) {
            _hasShownProfileSetup = true;
            
            final prefs = await SharedPreferences.getInstance();
            final hasSeenWorkerOnboarding = prefs.getBool('has_seen_worker_onboarding') ?? false;
            
            if (!hasSeenWorkerOnboarding && mounted) {
              await prefs.setBool('has_seen_worker_onboarding', true);
              _showProfileSetupModal();
            }
          }
        });
      }
    }
  }

  void _showProfileSetupModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerOnboardingScreen(),
      ),
    ).then((_) {
      // Re-fetch profile logic here if necessary, or just rely on state
      _checkProfileStatus();
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
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.work_outline, Icons.work, 'Jobs'),
              _buildNavItem(2, Icons.history_outlined, Icons.history, 'History'),
              _buildNavItem(3, Icons.mail_outline, Icons.mail, 'Messages'),
              _buildNavItem(4, Icons.settings_outlined, Icons.settings, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? Colors.black : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey, 
              fontSize: 11, 
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }
}
