import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/screens/edit_address_screen.dart';
import 'package:skillpay/services/customer_profile_service.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final CustomerProfileService _service = CustomerProfileService();
  late Future<List<Map<String, dynamic>>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _service.fetchSavedAddresses();
  }

  void _refresh() {
    setState(() {
      _addressesFuture = _service.fetchSavedAddresses();
    });
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _service.deleteAddress(id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Addresses',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading addresses.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textMedium),
              ),
            );
          }

          final addresses = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              if (addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No saved addresses yet.\nTap "Add New" to add your first address.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 15, height: 1.8),
                  ),
                ),
              ...addresses.asMap().entries.map((entry) {
                final address = entry.value;
                return _buildAddressCard(address);
              }),
              if (addresses.isNotEmpty) const SizedBox(height: 8),
              // Add New Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditAddressScreen()),
                    );
                    if (result == true) _refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Add New',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined, color: AppColors.primaryDark, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['street'] ?? address['full_address'] ?? 'Address',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                if (address['city'] != null || address['state'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [address['city'], address['state'], address['country']]
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .join(', '),
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
                if (address['phone'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    address['phone'].toString(),
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteAddress(address['id'].toString()),
            icon: const Icon(Icons.delete_outline, color: AppColors.textMedium, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete address',
          ),
        ],
      ),
    );
  }
}
