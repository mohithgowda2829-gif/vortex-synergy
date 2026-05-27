class DeliveryTask {
  const DeliveryTask({
    required this.id,
    required this.claimId,
    required this.receiverId,
    required this.donorId,
    required this.resourceTitle,
    required this.receiverName,
    required this.donorName,
    required this.orderNumber,
    required this.vehicleNumber,
    required this.agentName,
    required this.agentMobile,
    required this.status,
    required this.pickupApprovedAt,
    required this.deliveredAt,
    required this.receiverConfirmedAt,
    required this.failedReason,
    required this.lastLatitude,
    required this.lastLongitude,
    required this.lastLocationUpdateAt,
    required this.notes,
  });

  final String id;
  final String claimId;
  final String receiverId;
  final String donorId;
  final String resourceTitle;
  final String receiverName;
  final String donorName;
  final String? orderNumber;
  final String? vehicleNumber;
  final String? agentName;
  final String? agentMobile;
  final String status;
  final DateTime? pickupApprovedAt;
  final DateTime? deliveredAt;
  final DateTime? receiverConfirmedAt;
  final String? failedReason;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastLocationUpdateAt;
  final String? notes;

  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

    return DeliveryTask(
      id: json['id']?.toString() ?? '',
      claimId: json['claimId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      donorId: json['donorId']?.toString() ?? '',
      resourceTitle: json['resourceTitle']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      agentName: json['agentName']?.toString(),
      agentMobile: json['agentMobile']?.toString(),
      status: json['status']?.toString() ?? '',
      pickupApprovedAt: parseDate(json['pickupApprovedAt']),
      deliveredAt: parseDate(json['deliveredAt']),
      receiverConfirmedAt: parseDate(json['receiverConfirmedAt']),
      failedReason: json['failedReason']?.toString(),
      lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
      lastLocationUpdateAt: parseDate(json['lastLocationUpdateAt']),
      notes: json['notes']?.toString(),
    );
  }
}
