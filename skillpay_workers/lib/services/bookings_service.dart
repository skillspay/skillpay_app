import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/booking_model.dart';

class BookingsService {
  final _api = ApiClient.instance;

  /// Fetch active bookings for the current artisan.
  Future<List<BookingModel>> fetchMyBookings() async {
    try {
      final data = await _api.get('/bookings/mine') as List<dynamic>;
      return data
          .map((json) => BookingModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching bookings: ${e.message}');
      return [];
    }
  }

  /// Fetch a single booking by ID.
  Future<BookingModel?> fetchBooking(String id) async {
    try {
      final data = await _api.get('/bookings/$id') as Map<String, dynamic>;
      return BookingModel.fromMap(data);
    } on ApiException catch (e) {
      debugPrint('Error fetching booking: ${e.message}');
      return null;
    }
  }

  /// Mark a booking as started (IN_PROGRESS).
  Future<void> startJob(String bookingId) async {
    try {
      await _api.patch('/bookings/$bookingId/start');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Mark a booking as completed.
  Future<void> completeJob(String bookingId) async {
    try {
      await _api.patch('/bookings/$bookingId/complete');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}
