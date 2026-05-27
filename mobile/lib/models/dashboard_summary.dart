class DashboardSummary {
  const DashboardSummary({
    required this.totalMealsSaved,
    required this.medicineKitsDistributed,
    required this.donorCount,
    required this.completedClaims,
    required this.expiredResourcesPreventedFromMisuse,
  });

  final int totalMealsSaved;
  final int medicineKitsDistributed;
  final int donorCount;
  final int completedClaims;
  final int expiredResourcesPreventedFromMisuse;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalMealsSaved: json['totalMealsSaved'] as int? ?? 0,
      medicineKitsDistributed: json['medicineKitsDistributed'] as int? ?? 0,
      donorCount: json['donorCount'] as int? ?? 0,
      completedClaims: json['completedClaims'] as int? ?? 0,
      expiredResourcesPreventedFromMisuse:
          json['expiredResourcesPreventedFromMisuse'] as int? ?? 0,
    );
  }
}
