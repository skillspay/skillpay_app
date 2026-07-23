import 'package:flutter/foundation.dart';
import 'api_client.dart';

class WalletService {
  final _api = ApiClient.instance;

  /// Fetch the artisan's wallet balance and summary.
  Future<Map<String, dynamic>?> fetchWallet() async {
    try {
      final data = await _api.get('/wallet/me');
      return data as Map<String, dynamic>?;
    } on ApiException catch (e) {
      debugPrint('Error fetching wallet: ${e.message}');
      return null;
    }
  }

  /// Fetch wallet transaction history.
  Future<List<Map<String, dynamic>>> fetchTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final data = await _api.get('/wallet/transactions', query: {
        'page': page,
        'limit': limit,
      }) as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching transactions: ${e.message}');
      return [];
    }
  }
}
