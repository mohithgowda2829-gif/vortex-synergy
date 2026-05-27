import '../models/paged_resource_result.dart';
import '../models/resource_item.dart';
import 'api_client.dart';

class ResourceApi {
  ResourceApi(this._client);

  final ApiClient _client;

  Future<PagedResourceResult> list(
    String token, {
    String? query,
    String? resourceType,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    String sort = 'EXPIRY',
    int page = 0,
    int size = 12,
  }) async {
    final Map<String, dynamic> json = await _client.get(
      '/resources',
      token: token,
      queryParameters: <String, String?>{
        'query': query,
        'resourceType': resourceType,
        'city': city,
        'area': area,
        'latitude': latitude?.toString(),
        'longitude': longitude?.toString(),
        'sort': sort,
        'page': page.toString(),
        'size': size.toString(),
      },
    ) as Map<String, dynamic>;

    return PagedResourceResult.fromJson(json);
  }

  Future<List<ResourceItem>> mine(String token) async {
    final List<dynamic> json = await _client.get('/resources/mine', token: token) as List<dynamic>;
    return json.map((dynamic item) => ResourceItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ResourceItem> getById(String token, String id) async {
    final Map<String, dynamic> json =
        await _client.get('/resources/$id', token: token) as Map<String, dynamic>;
    return ResourceItem.fromJson(json);
  }

  Future<ResourceItem> create(String token, Map<String, dynamic> body) async {
    final Map<String, dynamic> json =
        await _client.post('/resources', token: token, body: body) as Map<String, dynamic>;
    return ResourceItem.fromJson(json);
  }

  Future<ResourceItem> update(String token, String id, Map<String, dynamic> body) async {
    final Map<String, dynamic> json =
        await _client.put('/resources/$id', token: token, body: body) as Map<String, dynamic>;
    return ResourceItem.fromJson(json);
  }

  Future<void> cancel(String token, String id) async {
    await _client.post('/resources/$id/cancel', token: token);
  }
}
