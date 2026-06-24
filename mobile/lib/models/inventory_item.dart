class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.resourceId,
    required this.claimId,
    required this.resourceTitle,
    required this.resourceType,
    required this.donorName,
    required this.quantityReceived,
    required this.quantityAvailable,
    required this.quantityConsumed,
    required this.quantityExpired,
    required this.unit,
    required this.status,
    required this.branchName,
    required this.storageLocation,
    required this.stockedAt,
    required this.lastConsumedAt,
    required this.foodExpiresAt,
    required this.medicineExpiryDate,
    required this.city,
    required this.area,
    required this.notes,
  });

  final String id;
  final String resourceId;
  final String? claimId;
  final String resourceTitle;
  final String resourceType;
  final String donorName;
  final int quantityReceived;
  final int quantityAvailable;
  final int quantityConsumed;
  final int quantityExpired;
  final String unit;
  final String status;
  final String? branchName;
  final String? storageLocation;
  final DateTime? stockedAt;
  final DateTime? lastConsumedAt;
  final DateTime? foodExpiresAt;
  final DateTime? medicineExpiryDate;
  final String city;
  final String area;
  final String? notes;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

    return InventoryItem(
      id: json['id']?.toString() ?? '',
      resourceId: json['resourceId']?.toString() ?? '',
      claimId: json['claimId']?.toString(),
      resourceTitle: json['resourceTitle']?.toString() ?? '',
      resourceType: json['resourceType']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      quantityReceived: json['quantityReceived'] as int? ?? 0,
      quantityAvailable: json['quantityAvailable'] as int? ?? 0,
      quantityConsumed: json['quantityConsumed'] as int? ?? 0,
      quantityExpired: json['quantityExpired'] as int? ?? 0,
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      branchName: json['branchName']?.toString(),
      storageLocation: json['storageLocation']?.toString(),
      stockedAt: parseDate(json['stockedAt']),
      lastConsumedAt: parseDate(json['lastConsumedAt']),
      foodExpiresAt: parseDate(json['foodExpiresAt']),
      medicineExpiryDate: parseDate(json['medicineExpiryDate']),
      city: json['city']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}
