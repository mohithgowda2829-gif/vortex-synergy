import '../models/delivery_task.dart';
import 'api_client.dart';

class DeliveryApi {
  DeliveryApi(this._client);

  final ApiClient _client;

  Future<DeliveryTask> assign(
    String token, {
    required String claimId,
    required String orderNumber,
    required String vehicleNumber,
    required String agentName,
    required String agentMobile,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/deliveries/assign',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'orderNumber': orderNumber,
        'vehicleNumber': vehicleNumber,
        'agentName': agentName,
        'agentMobile': agentMobile,
        'lastLatitude': latitude,
        'lastLongitude': longitude,
        'notes': notes,
      },
    ) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<DeliveryTask> byClaim(String token, String claimId) async {
    final Map<String, dynamic> json =
        await _client.get('/deliveries/$claimId', token: token) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<DeliveryTask> pickupApprove(
    String token, {
    required String claimId,
    required String pickupCode,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/deliveries/pickup-approve',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'latitude': latitude,
        'longitude': longitude,
        'pickupCode': pickupCode,
        'note': note,
      },
    ) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<DeliveryTask> inTransit(
    String token, {
    required String claimId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/deliveries/in-transit',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'latitude': latitude,
        'longitude': longitude,
        'note': note,
      },
    ) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<DeliveryTask> delivered(
    String token, {
    required String claimId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/deliveries/delivered',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'latitude': latitude,
        'longitude': longitude,
        'note': note,
      },
    ) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<DeliveryTask> confirmReceipt(
    String token, {
    required String claimId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/deliveries/confirm-receipt',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'latitude': latitude,
        'longitude': longitude,
        'note': note,
      },
    ) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<DeliveryTask> fail(
    String token, {
    required String claimId,
    required String failedReason,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/deliveries/fail',
      token: token,
      body: <String, dynamic>{'claimId': claimId, 'failedReason': failedReason},
    ) as Map<String, dynamic>;
    return DeliveryTask.fromJson(json);
  }

  Future<List<DeliveryTask>> receiver(String token) async {
    final List<dynamic> json = await _client.get('/deliveries/receiver', token: token) as List<dynamic>;
    return json.map((dynamic item) => DeliveryTask.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<DeliveryTask>> donor(String token) async {
    final List<dynamic> json = await _client.get('/deliveries/donor', token: token) as List<dynamic>;
    return json.map((dynamic item) => DeliveryTask.fromJson(item as Map<String, dynamic>)).toList();
  }
}
