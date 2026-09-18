import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/widgets/auth_widgets.dart';
import 'package:skillpay/services/jobs_service.dart';
import 'package:skillpay/services/customer_profile_service.dart';
import 'package:skillpay/services/categories_service.dart';

import 'package:skillpay/models/job_model.dart';
import 'package:skillpay/models/category_model.dart';

class CreateJobScreen extends StatefulWidget {
  final JobModel? initialJob;
  
  const CreateJobScreen({super.key, this.initialJob});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _budgetController = TextEditingController();
  final JobsService _jobsService = JobsService();
  
  String? _selectedCategory;
  List<CategoryModel> _categories = [];
  List<String> _categoryItems = ['Plumbing', 'Electrical', 'Cleaning'];
  String? _selectedTimeline;
  List<String> _timelineItems = ['Flexible', 'Urgent', 'Next 48 Hours'];
  String? _selectedLocation;
  List<String> _savedLocations = [];
  File? _selectedFile;
  String? _selectedFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _loadCategories();
    
    if (widget.initialJob != null) {
      final job = widget.initialJob!;
      _titleController.text = job.title;
      _detailsController.text = job.description;
      _budgetController.text = '\$${job.budget.toStringAsFixed(2)}';
      if (job.categoryName.isNotEmpty) {
        _selectedCategory = job.categoryName;
        if (!_categoryItems.contains(_selectedCategory)) {
          _categoryItems.add(_selectedCategory!);
        }
      }
      
      if (job.address.isNotEmpty) {
        _selectedLocation = job.address;
        if (!_savedLocations.contains(_selectedLocation)) {
          _savedLocations.add(_selectedLocation!);
        }
      }
      // Note: We don't fetch original image urls here for picker, it would require a separate flow
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoriesService().fetchCategories();
      if (categories.isNotEmpty && mounted) {
        setState(() {
          _categories = categories;
          _categoryItems = categories.map((c) => c.name).toList();
          if (_selectedCategory != null && !_categoryItems.contains(_selectedCategory)) {
            _categoryItems.add(_selectedCategory!);
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> _loadSavedLocations() async {
    try {
      final addresses = await CustomerProfileService().fetchAddresses();
      if (addresses.isNotEmpty && mounted) {
        setState(() {
          // Build display strings from structured address data
          final fetchedAddresses = addresses.map((a) {
            return a['address']?.toString() ?? a['label']?.toString() ?? 'Unknown Location';
          }).toList();
          
          for (var address in fetchedAddresses) {
            if (!_savedLocations.contains(address)) {
              _savedLocations.add(address);
            }
          }
          
          // Auto-select first address if not in edit mode with a valid location
          if (_savedLocations.isNotEmpty && _selectedLocation == null) {
            _selectedLocation = _savedLocations.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load saved locations: \$e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedFile = File(picked.path);
          _selectedFileName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _onCreateJob() async {
    if (_titleController.text.isEmpty || _budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out the title and budget')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileService = CustomerProfileService();
      final profile = await profileService.fetchProfile();
      final isVerified = profile?['user']?['isVerified'] == true || profile?['isVerified'] == true || profile?['is_verified'] == true;
      if (!isVerified) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only verified homeowners can create jobs. Please complete verification.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      List<String>? uploadedUrls;
      if (_selectedFile != null) {
        uploadedUrls = await _jobsService.uploadJobImages([_selectedFile!]);
      }

      String? categoryId;
      if (_selectedCategory != null) {
        final match = _categories.where((c) => c.name == _selectedCategory).toList();
        if (match.isNotEmpty) {
          categoryId = match.first.id;
        }
      }

      if (widget.initialJob != null) {
        // Edit mode
        await _jobsService.updateJob(
          widget.initialJob!.id,
          title: _titleController.text.trim(),
          description: _detailsController.text.trim(),
          address: _selectedLocation ?? 'Location not provided',
          budget: double.tryParse(_budgetController.text.replaceAll('\$', '').trim()) ?? 0.0,
          preferredDate: _selectedTimeline ?? 'Flexible',
          categoryId: categoryId ?? '', 
          imageUrls: uploadedUrls, // only patch if there are new images
        );
      } else {
        // Create mode
        await _jobsService.createJob(
          title: _titleController.text.trim(),
          description: _detailsController.text.trim(),
          address: _selectedLocation ?? 'Location not provided',
          budget: double.tryParse(_budgetController.text.replaceAll('\$', '').trim()) ?? 0.0,
          preferredDate: _selectedTimeline ?? 'Flexible',
          categoryId: categoryId ?? '', 
          imageUrls: uploadedUrls,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.initialJob != null ? 'Edit job' : 'Create new job',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Job Title'),
            buildAuthTextField(
              controller: _titleController,
              hint: 'Enter job title',
            ),
            const SizedBox(height: 20),

            _buildLabel('Job Category'),
            _buildDropdown(
              hint: 'Select Category',
              value: _selectedCategory,
              items: _categoryItems,
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Location'),
                if (_savedLocations.isEmpty)
                  Text(
                    'No saved address',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
              ],
            ),
            _savedLocations.isNotEmpty
                ? _buildDropdown(
                    hint: 'Select saved location',
                    value: _selectedLocation,
                    items: _savedLocations,
                    onChanged: (val) => setState(() => _selectedLocation = val),
                    icon: Icons.location_on_outlined,
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      'Please add an address in your Profile first.',
                      style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 15),
                    ),
                  ),
            const SizedBox(height: 20),

            _buildLabel('Additional Details'),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Enter description',
                hintStyle: GoogleFonts.outfit(fontSize: 15, color: AppColors.textLight),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('File upload'),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.primary
                        : const Color(0xFFE0E0E0),
                    width: _selectedFile != null ? 1.5 : 1,
                  ),
                ),
                child: _selectedFile != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.primaryDark, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedFileName ?? 'File selected',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                  }),
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.textMedium),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined,
                                color: AppColors.textMedium),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload a file',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Job Timeline'),
            _buildDropdown(
              hint: 'Select Timeline',
              value: _selectedTimeline,
              items: _timelineItems,
              onChanged: (val) => setState(() => _selectedTimeline = val),
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 20),

            _buildLabel('Budget'),
            buildAuthTextField(
              controller: _budgetController,
              hint: '\$ 0.00',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),

            // Fixed bottom create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onCreateJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark),
                      )
                    : Text(
                        widget.initialJob != null ? 'Save Changes' : 'Create job',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textLight),
          ),
          icon: Icon(icon ?? Icons.keyboard_arrow_down_rounded, color: AppColors.textMedium),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
