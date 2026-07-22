import 'package:flutter/material.dart';
import 'onboarding_step3_screen.dart';

class OnboardingStep2Screen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;

  const OnboardingStep2Screen({super.key, required this.onboardingData});

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  String? _selectedProfession;
  String? _selectedExperience;
  String? _employedStatus;
  final TextEditingController _jobTitleController = TextEditingController();
  
  bool _idUploaded = false;
  bool _passportUploaded = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _jobTitleController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = _selectedProfession != null &&
        _selectedExperience != null &&
        _employedStatus != null &&
        _jobTitleController.text.isNotEmpty &&
        _idUploaded &&
        _passportUploaded;
        
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
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
                      
                      // Progress Tracker
                      _buildProgressIndicator(),
                      
                      const SizedBox(height: 32),
                      const Text(
                        'Professional Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Profession
                      const Text('What is your profession?', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        value: _selectedProfession,
                        hint: 'Select profession',
                        items: ['Plumber', 'Electrician', 'Carpenter', 'Tailor', 'Mechanic'],
                        onChanged: (val) {
                          setState(() {
                            _selectedProfession = val;
                            _validateForm();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Experience
                      const Text('Years of experience', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        value: _selectedExperience,
                        hint: 'Select years of experience',
                        items: ['Less than 1 year', '1 - 3 years', '4 - 6 years', '7+ years'],
                        onChanged: (val) {
                          setState(() {
                            _selectedExperience = val;
                            _validateForm();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Employment
                      const Text('Are you currently employed in your field of work?', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceButton('Yes'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildChoiceButton('No'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Job Title
                      const Text('What is your job title?', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _jobTitleController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintText: 'e.g Senior Plumber',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Upload ID
                      const Text('Upload a valid ID card', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                      const SizedBox(height: 24),
                      
                      // Upload Passport
                      const Text('Upload your passport photograph', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildUploadBox(
                        isUploaded: _passportUploaded,
                        onTap: () {
                          setState(() {
                            _passportUploaded = true;
                            _validateForm();
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFormValid ? () {
                    final currentData = Map<String, dynamic>.from(widget.onboardingData);
                    currentData.addAll({
                      'profession': _selectedProfession,
                      'experience_years': _selectedExperience,
                      'is_employed': _employedStatus == 'Yes',
                      'job_title': _jobTitleController.text.trim(),
                    });
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OnboardingStep3Screen(
                        onboardingData: currentData,
                      )),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid 
                        ? const Color(0xFFFFC107) 
                        : const Color(0xFFFDE69F),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFFDE69F),
                    disabledForegroundColor: Colors.black54,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String value) {
    bool isSelected = _employedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _employedStatus = value;
          _validateForm();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC107) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadBox({required bool isUploaded, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50], // light grey area
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStep(label: 'Personal', step: '1', isActive: false, isCompleted: true),
        _buildConnector(isActive: true),
        _buildStep(label: 'Professional', step: '2', isActive: true, isCompleted: false),
        _buildConnector(isActive: false),
        _buildStep(label: 'Guarantor', step: '3', isActive: false, isCompleted: false),
      ],
    );
  }

  Widget _buildStep({required String label, required String step, required bool isActive, required bool isCompleted}) {
    Color color = isActive || isCompleted ? Colors.black : Colors.grey[300]!;
    Color textColor = isActive || isCompleted ? Colors.white : Colors.black;
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isCompleted 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(step, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted ? Colors.black : Colors.grey,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
