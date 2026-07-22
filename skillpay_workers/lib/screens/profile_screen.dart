import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Fetch base user profile info
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        // Fetch worker profile info
        final workerProfile = await Supabase.instance.client
            .from('worker_profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        final Map<String, dynamic> combined = {};
        if (userProfile != null) combined.addAll(userProfile);
        if (workerProfile != null) combined.addAll(workerProfile);
        
        // Use user metadata as fallback for first/last name
        if (combined['first_name'] == null) {
          combined['first_name'] = user.userMetadata?['first_name'];
        }
        if (combined['last_name'] == null) {
          combined['last_name'] = user.userMetadata?['last_name'];
        }
        if (combined['email'] == null) {
          combined['email'] = user.email;
        }

        if (mounted) {
          setState(() {
            _profileData = combined;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                          image: _profileData['profile_image_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(_profileData['profile_image_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileData['profile_image_url'] == null 
                            ? const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 40,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Change photo',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                  ),
                )
              else ...[
                const Text(
                  'Personal Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Personal Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoItem('Name', '${_profileData['first_name'] ?? ''} ${_profileData['last_name'] ?? ''}'.trim().isEmpty ? 'Not set' : '${_profileData['first_name'] ?? ''} ${_profileData['last_name'] ?? ''}'.trim()),
                      const Divider(height: 1),
                      _buildInfoItem('Email', _profileData['email'] ?? 'Not set'),
                      const Divider(height: 1),
                      _buildInfoItem('Phone Number', _profileData['phone_number'] ?? 'Not set'),
                      const Divider(height: 1),
                      _buildInfoItem('Home address', _profileData['home_address'] ?? 'Not set', isLast: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Work Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Work Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoItem('Profession', _profileData['profession'] ?? 'Not set'),
                      const Divider(height: 1),
                      _buildInfoItem('Experience', _profileData['experience'] ?? 'Not set'),
                      const Divider(height: 1),
                      _buildInfoItem('Guarantor Name', '${_profileData['guarantor_first_name'] ?? ''} ${_profileData['guarantor_last_name'] ?? ''}'.trim().isEmpty ? 'Not set' : '${_profileData['guarantor_first_name'] ?? ''} ${_profileData['guarantor_last_name'] ?? ''}'.trim()),
                      const Divider(height: 1),
                      _buildInfoItem('Guarantor Phone', _profileData['guarantor_phone'] ?? 'Not set', isLast: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Account Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Account Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildActionItem('Profile Settings', showArrow: true),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: isLast ? 16 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, {bool showArrow = false, bool isLast = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: isLast ? 16 : 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
