import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart';
import 'proposal_submitted_modal.dart';

class EditProposalScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const EditProposalScreen({super.key, this.profileData});

  @override
  State<EditProposalScreen> createState() => _EditProposalScreenState();
}

class _EditProposalScreenState extends State<EditProposalScreen> {
  late TextEditingController _coverLetterController;
  final ImagePicker _picker = ImagePicker();
  final List<String> _uploadedPhotoUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final bio = widget.profileData?['bio']?.toString() ?? 
        'I am a professional and technical plumbing engineer...';
    _coverLetterController = TextEditingController(text: bio);
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

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final response = await ApiClient.instance.uploadFile(
        '/storage/job-image',
        file: File(image.path),
        fieldName: 'file',
      );
      
      final url = (response as Map<String, dynamic>)['url'] as String;

      setState(() {
        _uploadedPhotoUrls.add(url);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileData = widget.profileData;
    final photoUrl = profileData?['profilePhoto']?.toString() ?? profileData?['profile_photo']?.toString();
    final name = profileData?['fullName']?.toString() ?? profileData?['full_name']?.toString() ?? 'Artisan Name';
    final categories = (profileData?['categories'] as List<dynamic>?) ?? [];
    final experience = profileData?['yearsExperience']?.toString() ?? profileData?['years_experience']?.toString() ?? '0';
    final hourlyRate = profileData?['hourlyRate']?.toString() ?? profileData?['hourly_rate']?.toString() ?? '0';
    final basedIn = profileData?['basedIn']?.toString() ?? profileData?['based_in']?.toString() ?? 'Location not specified';
    final workPreference = profileData?['workPreference']?.toString() ?? profileData?['work_preference']?.toString() ?? 'Not specified';
    
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Info (same as submit proposal)
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
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
              _buildSpecRow('Based in', basedIn),
              const SizedBox(height: 12),
              _buildSpecRow('Work preference', workPreference),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Starting rate', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text('\$$hourlyRate / hr', style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Cover Letter Input
              const Text(
                'Cover letter',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _coverLetterController,
                  maxLines: null,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Upload Photo box
              const Text(
                'Upload photo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadPhoto,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploading)
                        const CircularProgressIndicator(color: Colors.black)
                      else ...[
                        const Icon(
                          Icons.backup_outlined,
                          color: Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click to upload',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_uploadedPhotoUrls.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _uploadedPhotoUrls.map((url) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Rating / Jobs
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                  const SizedBox(width: 4),
                  const Text('4.7 Rating', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 4),
                  const Text('46 completed jobs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showSuccessModal, // Show modal on save
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }

  Widget _buildMockWorkImage() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
           image: NetworkImage('https://images.unsplash.com/photo-1581092160562-40aa08e78837?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=150&q=80'),
           fit: BoxFit.cover,
        ),
      ),
    );
  }
}
