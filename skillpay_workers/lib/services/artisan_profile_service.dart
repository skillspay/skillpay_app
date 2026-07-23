import 'package:flutter/foundation.dart';
import 'api_client.dart';

class ArtisanProfileService {
  final _api = ApiClient.instance;

  /// Fetch the current artisan's full profile.
  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final data = await _api.get('/artisans/profile');
      return data as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      throw Exception(e.message);
    }
  }

  /// Update artisan profile fields.
  Future<void> updateProfile({
    String? fullName,
    String? businessName,
    String? bio,
    String? experience,
    int? yearsExperience,
    double? hourlyRate,
    String? availabilityStatus,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _api.patch('/artisans/profile', body: {
        if (fullName != null) 'fullName': fullName,
        if (businessName != null) 'businessName': businessName,
        if (bio != null) 'bio': bio,
        if (experience != null) 'experience': experience,
        if (yearsExperience != null) 'yearsExperience': yearsExperience,
        if (hourlyRate != null) 'hourlyRate': hourlyRate,
        if (availabilityStatus != null) 'availabilityStatus': availabilityStatus,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Set availability status: AVAILABLE | BUSY | UNAVAILABLE
  Future<void> setAvailability(String status) async {
    try {
      await _api.patch('/artisans/profile', body: {'availabilityStatus': status});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Add a service category to the artisan's skills.
  Future<void> addCategory(String categoryId) async {
    try {
      await _api.post('/artisans/categories', body: {'categoryId': categoryId});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Remove a service category.
  Future<void> removeCategory(String categoryId) async {
    try {
      await _api.delete('/artisans/categories/$categoryId');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch all available service categories.
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final data = await _api.get('/categories') as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching categories: ${e.message}');
      return [];
    }
  }
}
