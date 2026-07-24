import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/artisan_profile_service.dart';
import '../models/artisan_profile_model.dart';
import 'document_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isEditing = false;
  String? _errorMessage;
  ArtisanProfileModel? _profile;

  final _profileService = ArtisanProfileService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Edit controllers
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _businessNameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _yearsExpCtrl;
  late TextEditingController _hourlyRateCtrl;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _businessNameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _yearsExpCtrl = TextEditingController();
    _hourlyRateCtrl = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessNameCtrl.dispose();
    _bioCtrl.dispose();
    _yearsExpCtrl.dispose();
    _hourlyRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _profileService.fetchProfile();
      if (data != null && mounted) {
        final profile = ArtisanProfileModel.fromMap(data);
        setState(() => _profile = profile);
        _populateControllers(profile);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateControllers(ArtisanProfileModel p) {
    _fullNameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phone ?? '';
    _businessNameCtrl.text = p.businessName ?? '';
    _bioCtrl.text = p.bio ?? '';
    _yearsExpCtrl.text =
        p.yearsExperience > 0 ? p.yearsExperience.toString() : '';
    _hourlyRateCtrl.text =
        p.hourlyRate != null ? p.hourlyRate!.toStringAsFixed(2) : '';
  }

  void _startEditing() => setState(() => _isEditing = true);

  void _cancelEditing() {
    if (_profile != null) _populateControllers(_profile!);
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await _profileService.updateProfile(
        fullName: _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
        businessName: _businessNameCtrl.text.trim().isEmpty
            ? null
            : _businessNameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        yearsExperience: _yearsExpCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_yearsExpCtrl.text.trim()),
        hourlyRate: _hourlyRateCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_hourlyRateCtrl.text.trim()),
      );

      await _fetchProfile();
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    XFile? xFile;
    try {
      xFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (xFile == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await _profileService.uploadProfilePhoto(File(xFile.path));
      // Refresh profile to show the new photo from the DB
      await _fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
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
          onPressed: () {
            if (_isEditing) {
              _cancelEditing();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _errorMessage == null)
            _isEditing
                ? Row(
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.black),
                    tooltip: 'Edit Profile',
                    onPressed: _startEditing,
                  ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black))
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
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Verification Banner ───────────────────────
                          _buildVerificationBanner(),

                          // ── Photo Area ────────────────────────────────
                          _buildPhotoArea(),

                          const SizedBox(height: 28),

                          // ── Personal Info ─────────────────────────────
                          _buildSectionHeader('Personal Info'),
                          const SizedBox(height: 12),
                          _buildCard(children: [
                            _buildField(
                              label: 'Full Name',
                              controller: _fullNameCtrl,
                              icon: Icons.person_outline,
                              editable: _isEditing,
                              hint: 'Your full name',
                            ),
                            _buildDivider(),
                            _buildField(
                              label: 'Email',
                              value: _profile?.email ?? 'Not set',
                              icon: Icons.mail_outline,
                              editable: false, // email via auth only
                            ),
                            _buildDivider(),
                            _buildField(
                              label: 'Phone',
                              controller: _phoneCtrl,
                              icon: Icons.phone_outlined,
                              editable: false, // phone lives on user model
                              hint: '+44 7700 900000',
                              keyboardType: TextInputType.phone,
                            ),
                          ]),

                          const SizedBox(height: 28),

                          // ── Work Profile ──────────────────────────────
                          _buildSectionHeader('Work Profile'),
                          const SizedBox(height: 12),
                          _buildCard(children: [
                            _buildField(
                              label: 'Business Name',
                              controller: _businessNameCtrl,
                              icon: Icons.business_outlined,
                              editable: _isEditing,
                              hint: 'Your business name',
                            ),
                            _buildDivider(),
                            _buildField(
                              label: 'Bio',
                              controller: _bioCtrl,
                              icon: Icons.notes_outlined,
                              editable: _isEditing,
                              hint: 'Tell clients about yourself…',
                              maxLines: 3,
                            ),
                            _buildDivider(),
                            _buildField(
                              label: 'Years of Experience',
                              controller: _yearsExpCtrl,
                              icon: Icons.work_history_outlined,
                              editable: _isEditing,
                              hint: 'e.g. 5',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            _buildDivider(),
                            _buildField(
                              label: 'Hourly Rate (£)',
                              controller: _hourlyRateCtrl,
                              icon: Icons.attach_money_outlined,
                              editable: _isEditing,
                              hint: 'e.g. 25.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                            _buildDivider(),
                            _buildField(
                              label: 'Categories',
                              value: _profile?.categoryNames.isNotEmpty == true
                                  ? _profile!.categoryNames.join(', ')
                                  : 'Not set',
                              icon: Icons.category_outlined,
                              editable: false,
                            ),
                          ]),

                          const SizedBox(height: 28),

                          // ── Account ───────────────────────────────────
                          _buildSectionHeader('Account'),
                          const SizedBox(height: 12),
                          _buildCard(children: [
                            _buildStatusRow(
                              'Verification',
                              _profile?.verificationStatus ?? 'UNVERIFIED',
                            ),
                            _buildDivider(),
                            _buildStatusRow(
                              'Availability',
                              _profile?.availabilityStatus ?? 'AVAILABLE',
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              'Completed Jobs',
                              '${_profile?.completedJobs ?? 0}',
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              'Average Rating',
                              _profile?.averageRating != null
                                  ? '${_profile!.averageRating.toStringAsFixed(1)} ★'
                                  : '—',
                            ),
                          ]),

                          const SizedBox(height: 32),

                          // ── Save Button ───────────────────────────────
                          if (_isEditing)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC107),
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor:
                                      const Color(0xFFFDE69F),
                                  disabledForegroundColor: Colors.black54,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black54,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Widget Builders ───────────────────────────────────────────────────────

  Widget _buildPhotoArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    image: _profile?.profilePhoto != null
                        ? DecorationImage(
                            image: NetworkImage(_profile!.profilePhoto!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profile?.profilePhoto == null
                      ? const Icon(Icons.person_outline,
                          color: Colors.white, size: 44)
                      : null,
                ),
                if (_isUploadingPhoto)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
            child: Text(
              _isUploadingPhoto ? 'Uploading…' : 'Change photo',
              style: TextStyle(
                color: _isUploadingPhoto ? Colors.grey : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVerificationBanner() {
    final status = _profile?.verificationStatus ?? 'UNVERIFIED';

    if (status == 'VERIFIED') return const SizedBox.shrink();

    Color bgColor = Colors.red[50]!;
    Color textColor = Colors.red[800]!;
    IconData icon = Icons.warning_amber_rounded;
    String message = 'Your account is unverified.';
    String actionText = 'Verify Now';
    bool canAct = true;

    if (status == 'PENDING') {
      bgColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
      icon = Icons.pending_actions_rounded;
      message = 'Verification is pending admin approval.';
      canAct = false;
    } else if (status == 'REJECTED') {
      message = 'Verification rejected. Please try again.';
      actionText = 'Upload Again';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canAct)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final didSubmit = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentVerificationScreen(),
                  ),
                );
                if (didSubmit == true) {
                  _fetchProfile(); // Refresh to show pending status
                }
              },
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[200]);

  Widget _buildField({
    required String label,
    TextEditingController? controller,
    String? value,
    required IconData icon,
    required bool editable,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (!editable) {
      final displayValue = controller?.text.isNotEmpty == true
          ? controller!.text
          : (value ?? 'Not set');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, size: 18, color: const Color(0xFFFFC107)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                labelStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    Color chipColor;
    Color textColor;
    switch (status.toUpperCase()) {
      case 'VERIFIED':
      case 'AVAILABLE':
        chipColor = const Color(0xFFE8F5E9);
        textColor = Colors.green[700]!;
        break;
      case 'PENDING':
      case 'BUSY':
        chipColor = const Color(0xFFFFF8E1);
        textColor = Colors.orange[700]!;
        break;
      default:
        chipColor = const Color(0xFFF5F5F5);
        textColor = Colors.grey[600]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status[0] + status.substring(1).toLowerCase(),
              style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
