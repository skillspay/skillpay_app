import 'dart:io';
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
    String? profilePhoto,
    String? basedIn,
    String? workPreference,
  }) async {
    try {
      await _api.patch('/artisans/profile', body: {
        'fullName': fullName,
        'businessName': businessName,
        'bio': bio,
        'experience': experience,
        'yearsExperience': yearsExperience,
        'hourlyRate': hourlyRate,
        'availabilityStatus': availabilityStatus,
        'latitude': latitude,
        'longitude': longitude,
        'profilePhoto': profilePhoto,
        'basedIn': basedIn,
        'workPreference': workPreference,
      }..removeWhere((_, v) => v == null));
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Upload a profile photo file to storage and save the URL to the artisan profile.
  /// Returns the public URL of the uploaded photo.
  Future<String> uploadProfilePhoto(File imageFile) async {
    try {
      final response = await _api.uploadFile(
        '/storage/profile-image',
        file: imageFile,
        fieldName: 'file',
      );
      final url = (response as Map<String, dynamic>)['url'] as String;
      // Persist the photo URL on the artisan profile
      await _api.patch('/artisans/profile', body: {'profilePhoto': url});
      return url;
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

  /// Upload a verification document file to storage.
  /// Returns the public URL of the uploaded document.
  Future<String> uploadVerificationDocument(File documentFile) async {
    try {
      final response = await _api.uploadFile(
        '/storage/verification-document',
        file: documentFile,
        fieldName: 'file',
      );
      final url = (response as Map<String, dynamic>)['url'] as String;
      return url;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Submit a verification document for admin review.
  Future<void> submitVerificationDocument({
    required String type,
    required String fileUrl,
  }) async {
    try {
      await _api.post('/artisans/verify', body: {
        'type': type,
        'fileUrl': fileUrl,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
