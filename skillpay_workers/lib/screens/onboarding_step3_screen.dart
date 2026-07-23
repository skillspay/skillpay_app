import 'package:flutter/material.dart';
import 'onboarding_success_screen.dart';
import '../services/artisan_profile_service.dart';
import '../services/api_client.dart';

class OnboardingStep3Screen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;

  const OnboardingStep3Screen({super.key, required this.onboardingData});

  @override
  State<OnboardingStep3Screen> createState() => _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState extends State<OnboardingStep3Screen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _idUploaded = false;
  bool _isFormValid = false;
  bool _isLoading = false;

  final _profileService = ArtisanProfileService();

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _emailController.text.contains('@') &&
        _phoneController.text.isNotEmpty &&
        _idUploaded;
    if (isValid != _isFormValid) setState(() => _isFormValid = isValid);
  }

  Future<void> _submitData() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      final data = widget.onboardingData;

      // Build the artisan profile update payload from all 3 steps
      await _profileService.updateProfile(
        fullName: '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim(),
        bio: data['job_title']?.toString(),
        experience: data['experience_years']?.toString(),
        yearsExperience: _parseYears(data['experience_years']?.toString()),
      );

      // Post the guarantor info via a dedicated endpoint (stored as metadata)
      try {
        await ApiClient.instance.post('/artisans/guarantor', body: {
          'guarantorFirstName': _firstNameController.text.trim(),
          'guarantorLastName': _lastNameController.text.trim(),
          'guarantorEmail': _emailController.text.trim(),
          'guarantorPhone': _phoneController.text.trim(),
        });
      } on ApiException {
        // Non-fatal if endpoint not yet implemented — log and continue
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingSuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _parseYears(String? raw) {
    if (raw == null) return 0;
    if (raw.contains('7+')) return 7;
    if (raw.contains('4')) return 4;
    if (raw.contains('1')) return 1;
    return 0;
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete onboarding and\nstart earning with SkillPay',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildProgressIndicator(),
                      const SizedBox(height: 32),
                      const Text('Guarantor Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Guarantor First name',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 8),
                                _buildTextField(
                                    controller: _firstNameController,
                                    hint: 'First name'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Guarantor Last name',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 8),
                                _buildTextField(
                                    controller: _lastNameController,
                                    hint: 'Last name'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Guarantor email address',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      const Text('Guarantor Phone number',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      const Text('Upload Guarantor valid ID card',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildUploadBox(
                        isUploaded: _idUploaded,
                        onTap: () {
                          setState(() {
                            _idUploaded = true;
                            _validateForm();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'NIN, Voters card, Driver\'s License, International Passport, Employment ID.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isFormValid && !_isLoading) ? _submitData : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFFDE69F),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFFDE69F),
                    disabledForegroundColor: Colors.black54,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUploadBox(
      {required bool isUploaded, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.backup_outlined,
              color: isUploaded ? Colors.green : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              isUploaded ? 'File Uploaded' : 'Click to upload',
              style: TextStyle(
                  color: isUploaded ? Colors.green : Colors.grey[600],
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStep(
            label: 'Personal', step: '1', isActive: false, isCompleted: true),
        _buildConnector(isActive: true),
        _buildStep(
            label: 'Professional',
            step: '2',
            isActive: false,
            isCompleted: true),
        _buildConnector(isActive: true),
        _buildStep(
            label: 'Guarantor', step: '3', isActive: true, isCompleted: false),
      ],
    );
  }

  Widget _buildStep(
      {required String label,
      required String step,
      required bool isActive,
      required bool isCompleted}) {
    final color =
        isActive || isCompleted ? Colors.black : Colors.grey[300]!;
    final textColor =
        isActive || isCompleted ? Colors.white : Colors.black;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(step,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: isActive || isCompleted ? Colors.black : Colors.grey,
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        height: 2,
        color: isActive ? Colors.black : Colors.grey[300],
      ),
    );
  }
}
