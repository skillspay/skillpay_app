import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/job_model.dart';

class JobsService {
  final _api = ApiClient.instance;

  /// Fetch all published jobs available for artisans to apply to.
  Future<List<JobModel>> fetchAvailableJobs({
    String? categoryId,
    double? latitude,
    double? longitude,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'status': 'PUBLISHED',
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
      };
      final data = await _api.get('/jobs', query: query) as List<dynamic>;
      return data
          .map((json) => JobModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching jobs: ${e.message}');
      return [];
    }
  }

  /// Fetch a single job by ID.
  Future<JobModel> fetchJob(String jobId) async {
    try {
      final data = await _api.get('/jobs/$jobId') as Map<String, dynamic>;
      return JobModel.fromMap(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch jobs the artisan has applied to (their applications).
  Future<List<JobModel>> fetchMyApplicationJobs() async {
    try {
      final data =
          await _api.get('/applications/my-jobs') as List<dynamic>;
      return data
          .map((json) => JobModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching application jobs: ${e.message}');
      return [];
    }
  }

  /// Fetch completed jobs (history) for the artisan.
  Future<List<JobModel>> fetchCompletedJobs() async {
    try {
      final data = await _api.get('/bookings/my-history') as List<dynamic>;
      return data
          .map((json) => JobModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching completed jobs: ${e.message}');
      return [];
    }
  }
}
