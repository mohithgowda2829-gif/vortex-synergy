class PendingVerification {
  const PendingVerification({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.verificationType,
    required this.status,
    required this.subjectName,
    required this.note,
    required this.createdAt,
    required this.reviewedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String verificationType;
  final String status;
  final String subjectName;
  final String? note;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

    return PendingVerification(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      verificationType: json['verificationType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: parseDate(json['createdAt']),
      reviewedAt: parseDate(json['reviewedAt']),
    );
  }
}
