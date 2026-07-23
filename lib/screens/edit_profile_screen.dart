import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/services/auth_service.dart';
import 'package:skillpay/services/customer_profile_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  File? _newProfileImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  final _authService = AuthService();
  final _profileService = CustomerProfileService();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final data = await _profileService.fetchProfile();
      if (data != null && mounted) {
        setState(() {
          _fullNameController.text = data['fullName']?.toString() ??
              data['full_name']?.toString() ?? '';
          _phoneController.text = data['user']?['phone']?.toString() ??
              data['phone']?.toString() ?? '';
          _emailController.text = data['user']?['email']?.toString() ??
              data['email']?.toString() ?? '';
          _currentImageUrl = data['profilePhoto']?.toString() ??
              data['profile_photo']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() => _newProfileImage = File(picked.path));
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_newProfileImage != null) {
        await _authService.uploadProfileImage(_newProfileImage!);
      }

      await _authService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim().isNotEmpty
            ? _dobController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Update failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Edit Profile',
          style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                          image: _newProfileImage != null
                              ? DecorationImage(
                                  image:
                                      FileImage(_newProfileImage!),
                                  fit: BoxFit.cover,
                                )
                              : _currentImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          _currentImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _newProfileImage == null &&
                                _currentImageUrl == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                label: 'Full Name',
                controller: _fullNameController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Email Address',
                controller: _emailController,
                readOnly: true,
                helperText: 'Email cannot be changed here.',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Date of Birth',
                controller: _dobController,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: readOnly ? AppColors.textMedium : AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle:
                GoogleFonts.outfit(color: const Color(0xFFBDBDBD)),
            helperText: helperText,
            helperStyle: GoogleFonts.outfit(
                color: AppColors.textMedium, fontSize: 12),
            filled: true,
            fillColor:
                readOnly ? const Color(0xFFF9F9F9) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
