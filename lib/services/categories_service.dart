import 'package:flutter/foundation.dart';
import 'package:skillpay/services/api_client.dart';
import 'package:skillpay/models/category_model.dart';

class CategoriesService {
  final _api = ApiClient.instance;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final data = await _api.get('/categories') as List<dynamic>;
      return data
          .map((json) => CategoryModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }
}
