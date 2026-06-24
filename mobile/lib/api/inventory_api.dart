import '../models/inventory_item.dart';
import 'api_client.dart';

class InventoryApi {
  InventoryApi(this._client);

  final ApiClient _client;

  Future<List<InventoryItem>> mine(String token) async {
    final List<dynamic> json = await _client.get('/inventory/my', token: token) as List<dynamic>;
    return json.map((dynamic item) => InventoryItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<InventoryItem> consume(
    String token, {
    required String inventoryItemId,
    required int quantity,
    String? branchName,
    String? storageLocation,
    String? notes,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/inventory/consume',
      token: token,
      body: <String, dynamic>{
        'inventoryItemId': inventoryItemId,
        'quantity': quantity,
        'branchName': branchName,
        'storageLocation': storageLocation,
        'notes': notes,
      },
    ) as Map<String, dynamic>;
    return InventoryItem.fromJson(json);
  }

  Future<InventoryItem> updateStorage(
    String token, {
    required String inventoryItemId,
    int quantity = 1,
    String? branchName,
    String? storageLocation,
    String? notes,
  }) async {
    final Map<String, dynamic> json = await _client.patch(
      '/inventory/storage',
      token: token,
      body: <String, dynamic>{
        'inventoryItemId': inventoryItemId,
        'quantity': quantity,
        'branchName': branchName,
        'storageLocation': storageLocation,
        'notes': notes,
      },
    ) as Map<String, dynamic>;
    return InventoryItem.fromJson(json);
  }
}
