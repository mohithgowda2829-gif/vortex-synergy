import 'api_client.dart';

class ReportApi {
  ReportApi(this._client);

  final ApiClient _client;

  Future<String> donationsCsv(String token) => _client.getText('/reports/donations/csv', token: token);

  Future<String> claimsCsv(String token) => _client.getText('/reports/claims/csv', token: token);

  Future<String> expiryCsv(String token) => _client.getText('/reports/expiry/csv', token: token);

  Future<String> medicineCsv(String token) => _client.getText('/reports/medicine/csv', token: token);

  Future<String> deliveryCsv(String token) => _client.getText('/reports/delivery/csv', token: token);
}
