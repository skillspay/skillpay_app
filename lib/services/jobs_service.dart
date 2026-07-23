import 'dart:io';
import 'package:skillpay/models/job_model.dart';
import 'package:skillpay/services/api_client.dart';

class JobsService {
  final _api = ApiClient.instance;

  /// Fetch all jobs created by the currently logged-in homeowner.
  Future<List<JobModel>> fetchMyJobs() async {
    try {
      final data = await _api.get('/jobs/my-jobs') as List<dynamic>;
      return data
          .map((json) => JobModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch a single job by ID.
  Future<JobModel> fetchJob(String jobId) async {
    try {
      final data =
          await _api.get('/jobs/$jobId') as Map<String, dynamic>;
      return JobModel.fromMap(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Create a new job request.
  Future<JobModel> createJob({
    required String categoryId,
    required String title,
    required String description,
    required double budget,
    required String address,
    double? latitude,
    double? longitude,
    String? preferredDate,
    List<String>? imageUrls,
  }) async {
    try {
      final data = await _api.post('/jobs', body: {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'budget': budget,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (preferredDate != null) 'preferredDate': preferredDate,
        if (imageUrls != null && imageUrls.isNotEmpty) 'images': imageUrls,
      }) as Map<String, dynamic>;
      return JobModel.fromMap(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Upload job images and return their public URLs.
  Future<List<String>> uploadJobImages(List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      try {
        final result = await _api.uploadFile(
          '/storage/job-image',
          file: image,
          fieldName: 'file',
        ) as Map<String, dynamic>;
        final url = result['url']?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      } on ApiException {
        // Skip failed uploads — non-fatal
      }
    }
    return urls;
  }

  /// Cancel a job (sets status → Cancelled).
  Future<void> cancelJob(String jobId) async {
    try {
      await _api.patch('/jobs/$jobId/cancel');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
