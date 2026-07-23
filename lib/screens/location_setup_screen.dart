import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/widgets/auth_widgets.dart';
import 'package:skillpay/screens/account_created_screen.dart';
import 'package:skillpay/services/auth_service.dart';
import 'package:skillpay/services/location_service.dart';

class LocationSetupScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String phone;
  final String userType;

  const LocationSetupScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.userType,
  });

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _townController = TextEditingController();
  final _stateController = TextEditingController();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;

  bool get _isFilled =>
      _addressController.text.trim().isNotEmpty &&
      _townController.text.trim().isNotEmpty &&
      _stateController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _addressController.dispose();
    _townController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      final coords = _locationService.formatCoordinates(position);

      // Pre-fill address with coordinates; town & state left for user to confirm.
      if (!mounted) return;
      setState(() {
        _addressController.text = coords;
        _isLocating = false;
      });

      // Show a snackbar guiding the user to fill in town/state.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location detected! Please fill in your town and state.',
            style: GoogleFonts.outfit(fontSize: 13),
          ),
          backgroundColor: AppColors.textDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _onContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullAddress =
          '${_addressController.text.trim()}, ${_townController.text.trim()}, ${_stateController.text.trim()}';

      await _authService.finishProfileSetup(
        email: widget.email,
        fullName: widget.fullName,
        phone: widget.phone,
        address: fullAddress,
        userType: widget.userType,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountCreatedScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            buildAuthBackButton(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Image.asset('assets/images/logo.png', height: 88),
                      const SizedBox(height: 24),
                      Text(
                        'Location setup',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your home, business or office location',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 14, color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 36),

                      // Address
                      buildAuthTextField(
                        controller: _addressController,
                        hint: 'Address',
                        icon: Icons.location_on_outlined,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your address' : null,
                      ),

                      const SizedBox(height: 10),

                      // Use current location button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _isLocating ? null : _useCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textDark,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  size: 18,
                                  color: AppColors.textDark,
                                ),
                          label: Text(
                            _isLocating ? 'Detecting location…' : 'Use my current location',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Town + State row
                      Row(
                        children: [
                          Expanded(
                            child: buildAuthTextField(
                              controller: _townController,
                              hint: 'Town',
                              icon: Icons.location_city_outlined,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildAuthTextField(
                              controller: _stateController,
                              hint: 'State',
                              icon: Icons.map_outlined,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      buildAuthPrimaryButton(
                        label: 'Continue',
                        enabled: _isFilled,
                        isLoading: _isLoading,
                        onTap: _onContinue,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) buildAuthErrorBanner(_errorMessage!),
            buildAuthFooter(),
          ],
        ),
      ),
    );
  }
}
