class ClaimItem {
  const ClaimItem({
    required this.id,
    required this.resourceId,
    required this.resourceTitle,
    required this.receiverName,
    required this.resourceType,
    required this.quantity,
    required this.status,
    required this.pickupCode,
    required this.reservedAt,
    required this.reservationExpiresAt,
    required this.confirmedAt,
    required this.claimedAt,
    required this.deliveryRequested,
    required this.pickupPersonName,
    required this.pickupPersonPhone,
    required this.pickupVehicleNumber,
    required this.pickupVehicleDetails,
    required this.pickupDetailsSubmittedAt,
    required this.pickupDetailsApproved,
    required this.pickupDetailsApprovedAt,
    required this.priorityScore,
    required this.priorityExplanation,
    required this.pickupConfirmedByReceiver,
    required this.handoverConfirmed,
  });

  final String id;
  final String resourceId;
  final String resourceTitle;
  final String receiverName;
  final String resourceType;
  final int quantity;
  final String status;
  final String? pickupCode;
  final DateTime? reservedAt;
  final DateTime? reservationExpiresAt;
  final DateTime? confirmedAt;
  final DateTime? claimedAt;
  final bool deliveryRequested;
  final String? pickupPersonName;
  final String? pickupPersonPhone;
  final String? pickupVehicleNumber;
  final String? pickupVehicleDetails;
  final DateTime? pickupDetailsSubmittedAt;
  final bool pickupDetailsApproved;
  final DateTime? pickupDetailsApprovedAt;
  final int? priorityScore;
  final String? priorityExplanation;
  final bool pickupConfirmedByReceiver;
  final bool handoverConfirmed;

  bool get hasPickupRepresentativeDetails =>
      (pickupPersonName?.trim().isNotEmpty ?? false) &&
      (pickupPersonPhone?.trim().isNotEmpty ?? false) &&
      (pickupVehicleNumber?.trim().isNotEmpty ?? false) &&
      (pickupVehicleDetails?.trim().isNotEmpty ?? false);

  factory ClaimItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

    return ClaimItem(
      id: json['id']?.toString() ?? '',
      resourceId: json['resourceId']?.toString() ?? '',
      resourceTitle: json['resourceTitle']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? '',
      resourceType: json['resourceType']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 0,
      status: json['status']?.toString() ?? '',
      pickupCode: json['pickupCode']?.toString(),
      reservedAt: parseDate(json['reservedAt']),
      reservationExpiresAt: parseDate(json['reservationExpiresAt']),
      confirmedAt: parseDate(json['confirmedAt']),
      claimedAt: parseDate(json['claimedAt']),
      deliveryRequested: json['deliveryRequested'] as bool? ?? false,
      pickupPersonName: json['pickupPersonName']?.toString(),
      pickupPersonPhone: json['pickupPersonPhone']?.toString(),
      pickupVehicleNumber: json['pickupVehicleNumber']?.toString(),
      pickupVehicleDetails: json['pickupVehicleDetails']?.toString(),
      pickupDetailsSubmittedAt: parseDate(json['pickupDetailsSubmittedAt']),
      pickupDetailsApproved: json['pickupDetailsApproved'] as bool? ?? false,
      pickupDetailsApprovedAt: parseDate(json['pickupDetailsApprovedAt']),
      priorityScore: json['priorityScore'] as int?,
      priorityExplanation: json['priorityExplanation']?.toString(),
      pickupConfirmedByReceiver: json['pickupConfirmedByReceiver'] as bool? ?? false,
      handoverConfirmed: json['handoverConfirmed'] as bool? ?? false,
    );
  }
}
