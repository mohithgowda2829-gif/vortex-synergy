class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.createdAt,
    required this.donorId,
    required this.donorName,
    required this.resourceType,
    required this.title,
    required this.description,
    required this.quantity,
    required this.availableQuantity,
    required this.unit,
    required this.status,
    required this.city,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.locationNote,
    required this.foodType,
    required this.preparedTime,
    required this.expiresAt,
    required this.medicineName,
    required this.medicineExpiryDate,
    required this.medicineSealStatus,
    required this.batchNumber,
    required this.medicineCategory,
    required this.medicineAccessType,
    required this.prescriptionRequired,
    required this.medicalVerificationStatus,
    required this.verificationNotes,
    required this.requiresReceiverDelivery,
    required this.photoUrls,
    required this.distanceKm,
    required this.claimable,
  });

  final String id;
  final DateTime? createdAt;
  final String donorId;
  final String donorName;
  final String resourceType;
  final String title;
  final String? description;
  final int quantity;
  final int availableQuantity;
  final String unit;
  final String status;
  final String city;
  final String area;
  final double? latitude;
  final double? longitude;
  final String? locationNote;
  final String? foodType;
  final DateTime? preparedTime;
  final DateTime? expiresAt;
  final DateTime? medicineExpiryDate;
  final String? medicineName;
  final String? medicineSealStatus;
  final String? batchNumber;
  final String? medicineCategory;
  final String? medicineAccessType;
  final bool? prescriptionRequired;
  final String medicalVerificationStatus;
  final String? verificationNotes;
  final bool requiresReceiverDelivery;
  final List<String> photoUrls;
  final double? distanceKm;
  final bool claimable;

  String? get primaryPhotoUrl => photoUrls.isEmpty ? null : photoUrls.first;

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

    return ResourceItem(
      id: json['id']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      donorId: json['donorId']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      resourceType: json['resourceType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      quantity: json['quantity'] as int? ?? 0,
      availableQuantity: json['availableQuantity'] as int? ?? 0,
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationNote: json['locationNote']?.toString(),
      foodType: json['foodType']?.toString(),
      preparedTime: parseDate(json['preparedTime']),
      expiresAt: parseDate(json['expiresAt']),
      medicineExpiryDate: parseDate(json['medicineExpiryDate']),
      medicineName: json['medicineName']?.toString(),
      medicineSealStatus: json['medicineSealStatus']?.toString(),
      batchNumber: json['batchNumber']?.toString(),
      medicineCategory: json['medicineCategory']?.toString(),
      medicineAccessType: json['medicineAccessType']?.toString(),
      prescriptionRequired: json['prescriptionRequired'] as bool?,
      medicalVerificationStatus: json['medicalVerificationStatus']?.toString() ?? '',
      verificationNotes: json['verificationNotes']?.toString(),
      requiresReceiverDelivery: json['requiresReceiverDelivery'] as bool? ?? false,
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      claimable: json['claimable'] as bool? ?? false,
    );
  }
}
