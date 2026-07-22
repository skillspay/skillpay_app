import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'jobs_tab.dart';
import 'history_tab.dart';
import 'messages_tab.dart';
import 'settings_tab.dart';
import 'profile_setup_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // Tracking if we need to show the One Last Step modal
  bool _needsProfileSetup = true;
  
  bool _isVerified = false;
  bool _isLoading = true;

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }
  
  Future<void> _checkVerificationStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Check verification from user_profiles
        final res = await Supabase.instance.client
            .from('user_profiles')
            .select('is_verified')
            .eq('id', user.id)
            .maybeSingle();
            
        if (res != null && res['is_verified'] == true) {
          setState(() {
            _isVerified = true;
          });
        }

        // Check profile completeness from worker_profiles
        final workerRes = await Supabase.instance.client
            .from('worker_profiles')
            .select('profile_image_url, cover_letter')
            .eq('user_id', user.id)
            .maybeSingle();

        // If the record doesn't exist yet or is missing image/cover_letter, show the modal
        if (workerRes == null || 
            workerRes['profile_image_url'] == null || 
            workerRes['cover_letter'] == null) {
          _needsProfileSetup = true;
        } else {
          _needsProfileSetup = false;
        }
      }
    } catch (e) {
      // Handle error quietly
    } finally {
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
  
  void _showProfileSetupModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: const ProfileSetupModal(),
        );
      },
    ).then((_) {
      // Logic after dialog is closed if needed
    });
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
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
