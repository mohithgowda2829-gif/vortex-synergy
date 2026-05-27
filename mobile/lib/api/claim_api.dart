import '../models/claim_item.dart';
import 'api_client.dart';

class ClaimApi {
  ClaimApi(this._client);

  final ApiClient _client;

  Future<ClaimItem> request(
    String token, {
    required String resourceId,
    required int quantity,
    required bool deliveryRequested,
    required bool urgentNeed,
    required bool vulnerableReceiver,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/claims/request',
      token: token,
      body: <String, dynamic>{
        'resourceId': resourceId,
        'quantity': quantity,
        'deliveryRequested': deliveryRequested,
        'urgentNeed': urgentNeed,
        'vulnerableReceiver': vulnerableReceiver,
      },
    ) as Map<String, dynamic>;
    return ClaimItem.fromJson(json);
  }

  Future<ClaimItem> confirm(String token, String claimId) async {
    final Map<String, dynamic> json = await _client.post(
      '/claims/confirm',
      token: token,
      body: <String, dynamic>{'claimId': claimId},
    ) as Map<String, dynamic>;
    return ClaimItem.fromJson(json);
  }

  Future<ClaimItem> cancel(String token, String claimId, {String? reason}) async {
    final Map<String, dynamic> json = await _client.post(
      '/claims/cancel',
      token: token,
      body: <String, dynamic>{'claimId': claimId, 'reason': reason},
    ) as Map<String, dynamic>;
    return ClaimItem.fromJson(json);
  }

  Future<ClaimItem> handover(String token, String claimId, String pickupCode) async {
    final Map<String, dynamic> json = await _client.post(
      '/claims/handover',
      token: token,
      body: <String, dynamic>{'claimId': claimId, 'pickupCode': pickupCode},
    ) as Map<String, dynamic>;
    return ClaimItem.fromJson(json);
  }

  Future<ClaimItem> submitPickupDetails(
    String token, {
    required String claimId,
    required String pickupPersonName,
    required String pickupPersonPhone,
    required String pickupVehicleNumber,
    required String pickupVehicleDetails,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/claims/pickup-details',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'pickupPersonName': pickupPersonName,
        'pickupPersonPhone': pickupPersonPhone,
        'pickupVehicleNumber': pickupVehicleNumber,
        'pickupVehicleDetails': pickupVehicleDetails,
      },
    ) as Map<String, dynamic>;
    return ClaimItem.fromJson(json);
  }

  Future<ClaimItem> approvePickupDetails(String token, String claimId) async {
    final Map<String, dynamic> json = await _client.post(
      '/claims/approve-pickup-details',
      token: token,
      body: <String, dynamic>{'claimId': claimId},
    ) as Map<String, dynamic>;
    return ClaimItem.fromJson(json);
  }

  Future<List<ClaimItem>> mine(String token) async {
    final List<dynamic> json = await _client.get('/claims/my', token: token) as List<dynamic>;
    return json.map((dynamic item) => ClaimItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ClaimItem>> donor(String token) async {
    final List<dynamic> json = await _client.get('/claims/donor', token: token) as List<dynamic>;
    return json.map((dynamic item) => ClaimItem.fromJson(item as Map<String, dynamic>)).toList();
  }
}
