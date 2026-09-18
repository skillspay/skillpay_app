import 'package:skillpay/services/api_client.dart';

class CustomerProfileService {
  final _api = ApiClient.instance;

  // ─── Fetch profile ────────────────────────────────────────────────────────

  /// Returns the full homeowner profile from NestJS.
  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final data = await _api.get('/homeowners/profile');
      return data as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      throw Exception(e.message);
    }
  }

  // ─── Addresses ────────────────────────────────────────────────────────────

  /// Fetch all saved addresses for the current homeowner.
  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    try {
      final data = await _api.get('/homeowners/addresses') as List<dynamic>;
      print('FETCH ADDRESSES RESPONSE: $data');
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on ApiException catch (e) {
      print('FETCH ADDRESSES ERROR: $e');
      throw Exception(e.message);
    }
  }

  /// Add a new saved address.
  Future<void> addAddress({
    required String label,
    required String address,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      await _api.post('/homeowners/addresses', body: {
        'label': label,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': isDefault,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update an existing address by ID.
  Future<void> updateAddress(
    String addressId, {
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      await _api.patch('/homeowners/addresses/$addressId', body: {
        if (label != null) 'label': label,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (isDefault != null) 'isDefault': isDefault,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a saved address by ID.
  Future<void> deleteAddress(String addressId) async {
    try {
      await _api.delete('/homeowners/addresses/$addressId');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Set an address as the default.
  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _api.patch('/homeowners/addresses/$addressId/set-default');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Preferred contact ────────────────────────────────────────────────────

  Future<void> updatePreferredContact(String contact) async {
    try {
      await _api.patch('/homeowners/profile', body: {
        'preferredContact': contact,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
