import 'package:flutter/material.dart';
import '../services/artisan_profile_service.dart';
import '../services/applications_service.dart';
import 'edit_proposal_screen.dart';
import 'proposal_submitted_modal.dart';

class SubmitProposalScreen extends StatefulWidget {
  final String? jobId;
  
  const SubmitProposalScreen({super.key, this.jobId});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _profileService = ArtisanProfileService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _profileData;
  final TextEditingController _priceController = TextEditingController();

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
          final hourlyRate = profile?['hourlyRate']?.toString() ?? profile?['hourly_rate']?.toString() ?? '0';
          _priceController.text = hourlyRate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return const ProposalSubmittedModal();
      },
    );
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
          const SizedBox(height: 16),
          const Text('Proposal Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Enter your proposal price',
            ),
          ),
          
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
                      MaterialPageRoute(builder: (context) => EditProposalScreen(profileData: _profileData)),
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
                  onPressed: _isSubmitting ? null : () async {
                    if (widget.jobId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: No job ID provided.'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    
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
                    
                    setState(() => _isSubmitting = true);
                    try {
                      final parsedPrice = double.tryParse(_priceController.text) ?? 0.0;
                      final bio = _profileData?['bio']?.toString() ?? 'No cover letter provided.';
                      
                      // Using the applications service
                      final appService = ApplicationsService();
                      await appService.submitApplication(
                        jobId: widget.jobId!,
                        price: parsedPrice,
                        proposal: bio,
                      );
                      
                      if (mounted) {
                        _showSuccessModal();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to submit proposal: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                      }
                    }
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
                  child: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
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
