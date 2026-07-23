import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/artisan_profile_service.dart';
import '../models/artisan_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ArtisanProfileModel? _profile;

  final _profileService = ArtisanProfileService();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _profileService.fetchProfile();
      if (data != null && mounted) {
        setState(() => _profile = ArtisanProfileModel.fromMap(data));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage',
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: _fetchProfile,
                            child: const Text('Retry')),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo Area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  image: _profile?.profilePhoto != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              _profile!.profilePhoto!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _profile?.profilePhoto == null
                                    ? const Icon(Icons.person_outline,
                                        color: Colors.white, size: 40)
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Change photo',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text('Personal Info',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              _buildInfoItem(
                                  'Name',
                                  _profile?.fullName.isNotEmpty == true
                                      ? _profile!.fullName
                                      : 'Not set'),
                              const Divider(height: 1),
                              _buildInfoItem(
                                  'Email', _profile?.email ?? 'Not set'),
                              const Divider(height: 1),
                              _buildInfoItem(
                                  'Phone', _profile?.phone ?? 'Not set',
                                  isLast: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        const Text('Work Profile',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              _buildInfoItem(
                                  'Business Name',
                                  _profile?.businessName ?? 'Not set'),
                              const Divider(height: 1),
                              _buildInfoItem(
                                  'Bio', _profile?.bio ?? 'Not set'),
                              const Divider(height: 1),
                              _buildInfoItem(
                                  'Experience',
                                  _profile?.experience ??
                                      (_profile?.yearsExperience != null
                                          ? '${_profile!.yearsExperience} years'
                                          : 'Not set')),
                              const Divider(height: 1),
                              _buildInfoItem(
                                  'Hourly Rate',
                                  _profile?.hourlyRate != null
                                      ? '\$${_profile!.hourlyRate!.toStringAsFixed(2)}/hr'
                                      : 'Not set'),
                              const Divider(height: 1),
                              _buildInfoItem(
                                  'Categories',
                                  _profile?.categoryNames.isNotEmpty == true
                                      ? _profile!.categoryNames.join(', ')
                                      : 'Not set',
                                  isLast: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        const Text('Account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              _buildActionItem('Profile Settings',
                                  showArrow: true),
                              const Divider(height: 1),
                              _buildActionItem('Certificate & ID'),
                              const Divider(height: 1),
                              _buildActionItem('Portfolio'),
                              const Divider(height: 1),
                              _buildActionItem('Settings', isLast: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 16, bottom: isLast ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title,
      {bool showArrow = false, bool isLast = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 16, bottom: isLast ? 16 : 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            if (showArrow)
              const Icon(Icons.chevron_right, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }
}
