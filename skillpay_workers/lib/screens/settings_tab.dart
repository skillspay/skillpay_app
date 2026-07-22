import 'package:flutter/material.dart';
import 'profile_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar Area
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                _buildSettingsTile(
                  title: 'Profile',
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  title: 'Proposal',
                  icon: Icons.assignment_outlined,
                  onTap: () {
                    // Navigate to Proposal
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  title: 'Transactions',
                  icon: Icons.swap_horiz_outlined,
                  onTap: () {
                    // Navigate to Transactions
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  title: 'Notification Settings',
                  icon: Icons.notifications_none_outlined,
                  onTap: () {
                    // Navigate to Notification Settings
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  title: 'Security',
                  icon: Icons.verified_user_outlined,
                  onTap: () {
                    // Navigate to Security
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  title: 'Help & Support',
                  icon: Icons.chat_bubble_outline,
                  onTap: () {
                    // Navigate to Help & Support
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  title: 'About',
                  icon: Icons.error_outline,
                  onTap: () {
                    // Navigate to About
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 24),
          ],
        ),
      ),
    );
  }
}
