import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_step2_screen.dart';

class OnboardingStep1Screen extends StatefulWidget {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  const OnboardingStep1Screen({
    super.key,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  @override
  State<OnboardingStep1Screen> createState() => _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends State<OnboardingStep1Screen> {
  String? _selectedGender;
  String? _dob;
  String? _selectedState;
  String? _selectedCountry;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    
    _emailController.text = widget.email ?? user?.email ?? '';
    _firstNameController.text = widget.firstName ?? user?.userMetadata?['first_name'] ?? '';
    _lastNameController.text = widget.lastName ?? user?.userMetadata?['last_name'] ?? '';
    _phoneController.text = widget.phone ?? user?.userMetadata?['phone_number'] ?? '';
    
    _validateForm();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _dob != null &&
        _selectedGender != null &&
        _addressController.text.isNotEmpty &&
        _selectedState != null &&
        _selectedCountry != null;
        
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFC107),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob = "${picked.day}/${picked.month}/${picked.year}";
        _validateForm();
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Complete onboarding and\nstarts earning with SkillPay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Progress Tracker
                      _buildProgressIndicator(),
                      
                      const SizedBox(height: 48),
                      
                      // First Name & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(controller: _firstNameController, hintText: 'First Name'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(controller: _lastNameController, hintText: 'Last Name'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Email & Phone
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(controller: _emailController, hintText: 'Email', readOnly: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(controller: _phoneController, hintText: 'Phone'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // DOB & Gender
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dob ?? 'Date of Birth',
                                        style: TextStyle(
                                          color: _dob != null ? Colors.black : Colors.grey,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedGender,
                              hint: 'Gender',
                              items: ['Male', 'Female', 'Other'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedGender = val;
                                  _validateForm();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildTextField(controller: _addressController, hintText: 'Address'),
                      const SizedBox(height: 16),

                      // State & Country
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedState,
                              hint: 'State',
                              items: ['Lagos', 'Abuja', 'Kano', 'Rivers'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedState = val;
                                  _validateForm();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              value: _selectedCountry,
                              hint: 'Country',
                              items: ['Nigeria', 'Ghana', 'Kenya'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedCountry = val;
                                  _validateForm();
                                });
                              },
                            ),
                          ),
                        ],
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
                    final onboardingData = {
                      'first_name': _firstNameController.text.trim(),
                      'last_name': _lastNameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'dob': _dob,
                      'gender': _selectedGender,
                      'address': _addressController.text.trim(),
                      'state': _selectedState,
                      'country': _selectedCountry,
                    };
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OnboardingStep2Screen(
                        onboardingData: onboardingData,
                      )),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid 
                        ? const Color(0xFFFFD54F) 
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[50] : Colors.transparent,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          style: const TextStyle(color: Colors.black, fontSize: 14),
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

  Widget _buildProgressIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildStep(label: 'Personal info', step: '01', isActive: true, isCompleted: false)),
        _buildConnector(isActive: false),
        Expanded(child: _buildStep(label: 'work info', step: '02', isActive: false, isCompleted: false)),
        _buildConnector(isActive: false),
        Expanded(child: _buildStep(label: 'Agreement', step: '03', isActive: false, isCompleted: false)),
      ],
    );
  }

  Widget _buildStep({required String label, required String step, required bool isActive, required bool isCompleted}) {
    Color bgColor = isActive || isCompleted ? Colors.black : Colors.white;
    Color borderColor = isActive || isCompleted ? Colors.black : Colors.grey[300]!;
    Color textColor = isActive || isCompleted ? Colors.white : Colors.black;
    Color labelColor = isActive ? Colors.black : Colors.grey;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: isCompleted 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(step, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Container(
      width: 40,
      margin: const EdgeInsets.only(top: 15, left: 4, right: 4),
      height: 2,
      color: isActive ? Colors.black : Colors.grey[300],
    );
  }
}
