import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_tab.dart';
import 'jobs_tab.dart';
import 'history_tab.dart';
import 'messages_tab.dart';
import 'settings_tab.dart';
import 'profile_setup_modal.dart';
import '../services/artisan_profile_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _needsProfileSetup = false;
  bool _isVerified = false;
  bool _isLoading = true;

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

        // Show setup modal if profile photo or bio is missing
        final hasPhoto = (profile['profilePhoto'] ?? profile['profile_photo']) != null;
        final hasBio = (profile['bio']?.toString() ?? '').isNotEmpty;
        _needsProfileSetup = !hasPhoto || !hasBio;
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
            HomeTab(isVerified: _isVerified),
            const JobsTab(),
            const HistoryTab(),
            const MessagesTab(),
            const SettingsTab(),
          ];
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_needsProfileSetup && mounted) {
            _showProfileSetupModal();
          }
        });
      }
    }
  }

  void _showProfileSetupModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: const ProfileSetupModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
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
    );
  }
}
