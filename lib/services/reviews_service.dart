import 'api_client.dart';

class ReviewsService {
  final ApiClient _api = ApiClient.instance;

  Future<void> submitReview({
    required String jobId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      await _api.post('/reviews/by-job/$jobId', body: {
        'rating': rating,
        if (reviewText != null && reviewText.isNotEmpty) 'review': reviewText,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to submit review');
    }
  }
}
