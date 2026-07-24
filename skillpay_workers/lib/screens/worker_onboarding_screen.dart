import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'dashboard_screen.dart';
import 'upload_profile_photo_screen.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  final String? fullName;
  final String? phone;
  final String? email;

  const WorkerOnboardingScreen({
    super.key,
    this.fullName,
    this.phone,
    this.email,
  });

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  
  int _currentPage = 0;
  bool _isLoading = false;

  // Step 1: Location Data
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  // Step 2: Skills & Rate
  String? _selectedCategory;
  final TextEditingController _rateController = TextEditingController();
  final List<Map<String, String>> _categories = [
    {'id': 'cat_plumbing', 'name': 'Plumbing', 'icon': '🔧'},
    {'id': 'cat_electrical', 'name': 'Electrical', 'icon': '⚡'},
    {'id': 'cat_cleaning', 'name': 'Cleaning', 'icon': '🧹'},
    {'id': 'cat_carpentry', 'name': 'Carpentry', 'icon': '🪚'},
    {'id': 'cat_painting', 'name': 'Painting', 'icon': '🎨'},
    {'id': 'cat_landscaping', 'name': 'Landscaping', 'icon': '🌱'},
  ];

  // Step 3: Bio & Photo
  final TextEditingController _bioController = TextEditingController();
  bool _hasPhoto = false;

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _townController.dispose();
    _stateController.dispose();
    _rateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_addressController.text.isEmpty || _townController.text.isEmpty || _stateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete your location details.')));
        return;
      }
    } else if (_currentPage == 1) {
      if (_selectedCategory == null || _rateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category and enter your rate.')));
        return;
      }
    }
    
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitOnboarding() async {
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a short bio.')));
      return;
    }
    if (!_hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a profile photo.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedCategory != null) {
        await _authService.addCategory(_selectedCategory!);
      }

      final rate = double.tryParse(_rateController.text.trim());
      await _authService.updateWorkerProfile(
        bio: _bioController.text.trim(),
        hourlyRate: rate,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await _locationService.getCurrentLocation();
      final placemarks = await _locationService.getAddressFromCoordinates(position);
      
      String addressText = '';
      String townText = '';
      String stateText = '';
      
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        addressText = [pm.subThoroughfare, pm.thoroughfare].where((s) => s != null && s.isNotEmpty).join(' ');
        if (addressText.isEmpty) {
          addressText = pm.street ?? addressText;
        }
        townText = pm.locality ?? pm.subLocality ?? '';
        stateText = pm.administrativeArea ?? '';
      } else {
        addressText = _locationService.formatCoordinates(position);
      }

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (addressText.isNotEmpty) _addressController.text = addressText;
        if (townText.isNotEmpty) _townController.text = townText;
        if (stateText.isNotEmpty) _stateController.text = stateText;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location detected successfully.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onUploadPhoto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadProfilePhotoScreen()),
    );
    if (result == true) {
      setState(() => _hasPhoto = true);
    }
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed, required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text(label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
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
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage >= index ? const Color(0xFFFFC107) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildLocationStep(),
                _buildSkillsStep(),
                _buildBioPhotoStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildPrimaryButton(
              label: _currentPage == 2 ? 'Complete Setup' : 'Continue',
              onPressed: _isLoading ? () {} : _nextPage,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where do you work?',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your location to connect you with nearby clients.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _isLocating ? null : _useCurrentLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  if (_isLocating)
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.my_location, color: Colors.blue),
                  const SizedBox(width: 16),
                  Text('Use my current location', style: GoogleFonts.outfit(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(label: 'Street Address', hint: '123 Main St', controller: _addressController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(label: 'Town/City', hint: 'Ikeja', controller: _townController)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(label: 'State', hint: 'Lagos', controller: _stateController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you do?',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your primary skill and set your base hourly rate.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          Text('Select a Category', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFC107) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isSelected ? const Color(0xFFFFC107) : Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        cat['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            label: 'Hourly Rate (₦)',
            hint: 'e.g. 5000',
            controller: _rateController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildBioPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stand out to clients',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo and a short bio to build trust.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: _onUploadPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _hasPhoto
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
                        : const Icon(Icons.person, color: Colors.grey, size: 48),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _hasPhoto ? 'Photo Uploaded!' : 'Upload Profile Photo',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Professional Bio',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _bioController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe your experience, expertise, and what makes you a great artisan...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
