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

  /// Fetch bank accounts
  Future<List<Map<String, dynamic>>> fetchBankAccounts() async {
    try {
      final data = await _api.get('/wallet/bank-accounts') as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on ApiException catch (e) {
      debugPrint('Error fetching bank accounts: ${e.message}');
      return [];
    }
  }

  /// Add a bank account
  Future<bool> addBankAccount(Map<String, dynamic> accountData) async {
    try {
      await _api.post('/wallet/bank-accounts', body: accountData);
      return true;
    } on ApiException catch (e) {
      debugPrint('Error adding bank account: ${e.message}');
      return false;
    }
  }

  /// Request a withdrawal
  Future<bool> requestWithdrawal(double amount) async {
    try {
      await _api.post('/wallet/withdraw', body: {'amount': amount});
      return true;
    } on ApiException catch (e) {
      debugPrint('Error requesting withdrawal: ${e.message}');
      throw Exception(e.message);
    }
  }
}
