import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/widgets/location_picker_widget.dart';
import 'package:skillpay/services/customer_profile_service.dart';

// Common phone country codes
const List<Map<String, String>> _phoneCodes = [
  {'code': '+1', 'name': 'US/CA'},
  {'code': '+44', 'name': 'UK'},
  {'code': '+234', 'name': 'NG'},
  {'code': '+233', 'name': 'GH'},
  {'code': '+27', 'name': 'ZA'},
  {'code': '+91', 'name': 'IN'},
  {'code': '+61', 'name': 'AU'},
  {'code': '+49', 'name': 'DE'},
  {'code': '+33', 'name': 'FR'},
  {'code': '+55', 'name': 'BR'},
  {'code': '+971', 'name': 'AE'},
  {'code': '+966', 'name': 'SA'},
  {'code': '+254', 'name': 'KE'},
  {'code': '+255', 'name': 'TZ'},
  {'code': '+256', 'name': 'UG'},
];

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({super.key});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedPhoneCode = '+1';
  String countryValue = '';
  String stateValue = '';
  String cityValue = '';
  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _phoneController.text.isNotEmpty &&
          _addressController.text.isNotEmpty &&
          countryValue.isNotEmpty &&
          stateValue.isNotEmpty &&
          cityValue.isNotEmpty;
    });
  }

  Future<void> _onSaveAddress() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);
    try {
      final service = CustomerProfileService();
      await service.addAddress(
        label: 'Home', // Or allow user to input
        address: '${_addressController.text.trim()}, $cityValue, $stateValue, $countryValue',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhoneCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Select Country Code',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(),
          ..._phoneCodes.map((entry) {
            final isSelected = _selectedPhoneCode == entry['code'];
            return ListTile(
              onTap: () {
                setState(() => _selectedPhoneCode = entry['code']!);
                Navigator.pop(context);
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry['name']!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : AppColors.textMedium,
                  ),
                ),
              ),
              title: Text(
                entry['code']!,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Text(
                entry['name']!,
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMedium),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
            );
          }),
        ],
      ),
    );
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
          'Add New Address',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Phone Number ──────────────────────────────────────────────
            Text(
              'Phone Number',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Country code button
                GestureDetector(
                  onTap: _showPhoneCodePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD0D0D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedPhoneCode,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Phone number text field
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFFBDBDBD)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Street Address ────────────────────────────────────────────
            Text(
              'Street Address',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              keyboardType: TextInputType.multiline,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter street address',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFFBDBDBD)),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 24),

            // ── Country / State / City ────────────────────────────────────
            LocationPickerWidget(
              onChanged: (country, state, city) {
                countryValue = country;
                stateValue = state;
                cityValue = city;
                _validateForm();
              },
            ),

            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _onSaveAddress : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withAlpha(100),
                  foregroundColor: Colors.black,
                  disabledForegroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Address',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
