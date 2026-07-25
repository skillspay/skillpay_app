import 'package:flutter/material.dart';
import '../services/artisan_profile_service.dart';
import 'edit_proposal_screen.dart';

class SubmitProposalScreen extends StatefulWidget {
  final String? jobId;
  
  const SubmitProposalScreen({super.key, this.jobId});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _profileService = ArtisanProfileService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await _profileService.fetchProfile();
      if (mounted) {
        setState(() {
          _profileData = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
          'Submit Proposal',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final photoUrl = _profileData?['profilePhoto']?.toString() ?? _profileData?['profile_photo']?.toString();
    final name = _profileData?['fullName']?.toString() ?? _profileData?['full_name']?.toString() ?? 'Artisan Name';
    final categories = (_profileData?['categories'] as List<dynamic>?) ?? [];
    final experience = _profileData?['yearsExperience']?.toString() ?? _profileData?['years_experience']?.toString() ?? '0';
    final hourlyRate = _profileData?['hourlyRate']?.toString() ?? _profileData?['hourly_rate']?.toString() ?? '0';
    final bio = _profileData?['bio']?.toString() ?? 'No cover letter or bio provided.';
    final completedJobs = _profileData?['completedJobs']?.toString() ?? '0';
    final rating = _profileData?['rating']?.toString() ?? '0.0';
    final isVerified = _profileData?['verificationStatus'] == 'VERIFIED' || _profileData?['verification_status'] == 'VERIFIED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image: photoUrl != null 
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                alignment: Alignment.topLeft,
                child: photoUrl == null ? const Center(child: Icon(Icons.person, color: Colors.grey)) : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        color: isVerified ? Colors.blue : Colors.orange,
                        size: 16,
                      ),
                    ],
                  ),
                  const Text(
                    'Your Profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (categories.isNotEmpty)
                    Row(
                      children: categories.take(2).map((cat) {
                        final catName = cat['category']?['name'] ?? 'Category';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildTag(catName.toString()),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 24),
          
          // Specs
          _buildSpecRow('Experience', '$experience years +'),
          const SizedBox(height: 12),
          _buildSpecRow('Starting rate', '\$$hourlyRate / hr', valueColor: Colors.green),
          
          const SizedBox(height: 24),
          
          // Cover Letter
          const Text(
            'Cover Letter / Bio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              bio,
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Rating / Jobs
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
              const SizedBox(width: 4),
              Text('$rating Rating', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 16),
              const SizedBox(width: 4),
              Text('$completedJobs completed jobs', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          
          const SizedBox(height: 48),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProposalScreen()),
                    ).then((_) => _fetchProfileData());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFC107),
                    side: const BorderSide(color: Color(0xFFFFC107)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Edit proposal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final isVerified = _profileData?['verificationStatus'] == 'VERIFIED' || _profileData?['verification_status'] == 'VERIFIED';
                    if (!isVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Only verified artisans can submit proposals. Please complete verification.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Logic to actually submit proposal to backend using widget.jobId
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[800], fontSize: 10),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: valueColor == Colors.black ? FontWeight.normal : FontWeight.bold)),
      ],
    );
  }
}
