import '../models/dashboard_summary.dart';
import '../models/role_dashboard_summary.dart';
import 'api_client.dart';

class DonorCertificate {
  const DonorCertificate({
    required this.donorName,
    required this.numberOfContributions,
    required this.impactCount,
  });

  final String donorName;
  final int numberOfContributions;
  final int impactCount;

  factory DonorCertificate.fromJson(Map<String, dynamic> json) {
    return DonorCertificate(
      donorName: json['donorName']?.toString() ?? '',
      numberOfContributions: json['numberOfContributions'] as int? ?? 0,
      impactCount: json['impactCount'] as int? ?? 0,
    );
  }
}

class DonorCertificateDetail {
  const DonorCertificateDetail({
    required this.donorName,
    required this.numberOfContributions,
    required this.impactCount,
    required this.certificateNumber,
    required this.issuedAt,
    required this.issuedBy,
    required this.programName,
    required this.statement,
  });

  final String donorName;
  final int numberOfContributions;
  final int impactCount;
  final String certificateNumber;
  final DateTime? issuedAt;
  final String issuedBy;
  final String programName;
  final String statement;

  factory DonorCertificateDetail.fromJson(Map<String, dynamic> json) {
    return DonorCertificateDetail(
      donorName: json['donorName']?.toString() ?? '',
      numberOfContributions: json['numberOfContributions'] as int? ?? 0,
      impactCount: json['impactCount'] as int? ?? 0,
      certificateNumber: json['certificateNumber']?.toString() ?? '',
      issuedAt: json['issuedAt'] == null ? null : DateTime.tryParse(json['issuedAt'].toString()),
      issuedBy: json['issuedBy']?.toString() ?? '',
      programName: json['programName']?.toString() ?? '',
      statement: json['statement']?.toString() ?? '',
    );
  }
}

class DashboardApi {
  DashboardApi(this._client);

  final ApiClient _client;

  Future<DashboardSummary> summary(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/dashboard/summary', token: token) as Map<String, dynamic>;
    return DashboardSummary.fromJson(json);
  }

  Future<RoleDashboardSummary> roleSummary(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/dashboard/role-summary', token: token) as Map<String, dynamic>;
    return RoleDashboardSummary.fromJson(json);
  }

  Future<DonorCertificate> donorCertificate(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/dashboard/donor-certificate', token: token) as Map<String, dynamic>;
    return DonorCertificate.fromJson(json);
  }

  Future<DonorCertificateDetail> donorCertificateDetail(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/dashboard/donor-certificate/detail', token: token) as Map<String, dynamic>;
    return DonorCertificateDetail.fromJson(json);
  }

  Future<String> donorCertificateDownload(String token) {
    return _client.getText('/dashboard/donor-certificate/download', token: token);
  }
}
