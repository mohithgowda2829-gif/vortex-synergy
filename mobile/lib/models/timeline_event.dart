class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.metadataJson,
    required this.createdAt,
  });

  final String id;
  final String actorName;
  final String action;
  final String targetType;
  final String targetId;
  final String? details;
  final String? metadataJson;
  final DateTime? createdAt;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? 'System',
      action: json['action']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      details: json['details']?.toString(),
      metadataJson: json['metadataJson']?.toString(),
      createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
