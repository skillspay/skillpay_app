import 'package:skillpay/models/worker_model.dart';
import 'package:skillpay/services/api_client.dart';

class WorkerService {
  final _api = ApiClient.instance;

  /// Fetch artisans near the homeowner's location.
  /// [latitude] and [longitude] are the homeowner's current coordinates.
  /// [categoryId] optionally filters by service category.
  /// [radiusKm] is the search radius in kilometres (default 20).
  Future<List<WorkerModel>> fetchNearbyWorkers({
    double? latitude,
    double? longitude,
    String? categoryId,
    int radiusKm = 20,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        'radiusKm': radiusKm,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (categoryId != null) 'categoryId': categoryId,
      };
      final data =
          await _api.get('/artisans/nearby', query: query) as List<dynamic>;
      return data
          .map((json) => WorkerModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch a single artisan's public profile.
  Future<WorkerModel> fetchArtisan(String artisanId) async {
    try {
      final data =
          await _api.get('/artisans/$artisanId') as Map<String, dynamic>;
      return WorkerModel.fromMap(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Search artisans by name or skill keyword.
  Future<List<WorkerModel>> searchArtisans(String query) async {
    try {
      final data = await _api.get('/artisans', query: {
        'search': query,
      }) as List<dynamic>;
      return data
          .map((json) => WorkerModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
