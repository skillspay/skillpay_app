import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/application_model.dart';

class ApplicationsService {
  final _api = ApiClient.instance;

  /// Submit a new job application (proposal).
  Future<ApplicationModel> submitApplication({
    required String jobId,
    required double price,
    required String proposal,
    String? estimatedDuration,
  }) async {
    try {
      final data = await _api.post('/applications', body: {
        'jobId': jobId,
        'price': price,
        'proposal': proposal,
        if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      }) as Map<String, dynamic>;
      return ApplicationModel.fromMap(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch all applications submitted by the current artisan.
  Future<List<ApplicationModel>> fetchMyApplications({String? status}) async {
    try {
      final query = <String, dynamic>{
        if (status != null) 'status': status,
      };
      final data =
          await _api.get('/applications/mine', query: query) as List<dynamic>;
      return data
          .map((json) => ApplicationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching applications: ${e.message}');
      return [];
    }
  }

  /// Fetch a single application by ID.
  Future<ApplicationModel?> fetchApplication(String id) async {
    try {
      final data =
          await _api.get('/applications/$id') as Map<String, dynamic>;
      return ApplicationModel.fromMap(data);
    } on ApiException catch (e) {
      debugPrint('Error fetching application: ${e.message}');
      return null;
    }
  }

  /// Update an existing application (edit proposal before it's accepted).
  Future<void> updateApplication(
    String id, {
    double? price,
    String? proposal,
    String? estimatedDuration,
  }) async {
    try {
      await _api.patch('/applications/$id', body: {
        if (price != null) 'price': price,
        if (proposal != null) 'proposal': proposal,
        if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Withdraw a pending application.
  Future<void> withdrawApplication(String id) async {
    try {
      await _api.patch('/applications/$id/withdraw');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
