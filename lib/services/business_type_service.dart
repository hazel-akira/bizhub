import '../models/business_type.dart';
import 'api_client.dart';

class BusinessTypeService {
  BusinessTypeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<BusinessTypeOption>> fetchTypes() async {
    final json = await _api.get('/api/business-types');
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => BusinessTypeOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
