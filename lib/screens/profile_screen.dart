import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/screens/edit_profile_screen.dart';
import 'package:skillpay/services/customer_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userProfileFuture;
  final _profileService = CustomerProfileService();

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _profileService.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // We will pass the current future data or let EditProfileScreen fetch it
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((_) {
                setState(() {
                  _userProfileFuture = _profileService.fetchProfile();
                });
              });
            },
            child: Text(
              'Edit',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: GoogleFonts.outfit(color: AppColors.textMedium),
              ),
            );
          }

          final data = snapshot.data;
          final fullName = data?['fullName']?.toString() ??
              data?['full_name']?.toString() ?? 'User';
          final parts = fullName.split(' ');
          final firstName = parts.isNotEmpty ? parts.first : '';
          final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          final email = data?['user']?['email']?.toString() ??
              data?['email']?.toString() ?? '';
          final phoneNumber = data?['user']?['phone']?.toString() ??
              data?['phone']?.toString() ??
              data?['phone_number']?.toString() ?? '';
          final profileImageUrl = data?['profilePhoto']?.toString() ??
              data?['profile_photo']?.toString();
          final gender = data?['gender']?.toString() ?? '';
          final dob = data?['dob'] != null
              ? _formatDate(data!['dob'].toString())
              : '';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Area
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: profileImageUrl != null
                        ? DecorationImage(
                            // Add a unique cache-busting parameter based on time to force Flutter to reload the new image
                            image: NetworkImage(
                              '$profileImageUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ).then((_) {
                      setState(() {
                        _userProfileFuture = _profileService.fetchProfile();
                      });
                    });
                  },
                  child: Text(
                    'Change photo',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark, // Matching the yellow text
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Form Fields (Display Only)
                _buildProfileField('First Name', firstName),
                _buildProfileField('Last Name', lastName),
                _buildProfileField('Email', email),
                _buildProfileField('Phone Number', phoneNumber),
                if (gender.isNotEmpty) _buildProfileField('Gender', gender),
                if (dob.isNotEmpty) _buildProfileField('Date of Birth', dob),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textMedium,
            ),
          ),
          Text(
            value.isNotEmpty ? value : '-',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
