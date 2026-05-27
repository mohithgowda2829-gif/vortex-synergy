class RoleDashboardSummary {
  const RoleDashboardSummary({
    required this.role,
    required this.unreadNotifications,
    required this.activeDonations,
    required this.claimedDonations,
    required this.expiredDonations,
    required this.assignedDeliveryCount,
    required this.activeClaims,
    required this.completedClaims,
    required this.activeDeliveryCount,
    required this.completedDeliveryCount,
    required this.urgentClaimCount,
    required this.pendingVerificationCount,
    required this.approvedVerificationCount,
    required this.rejectedVerificationCount,
    required this.pendingUserApprovalCount,
    required this.moderatedResourceCount,
    required this.activeSystemDeliveryCount,
    required this.totalMealsSaved,
    required this.medicineKitsDistributed,
  });

  final String role;
  final int unreadNotifications;
  final int activeDonations;
  final int claimedDonations;
  final int expiredDonations;
  final int assignedDeliveryCount;
  final int activeClaims;
  final int completedClaims;
  final int activeDeliveryCount;
  final int completedDeliveryCount;
  final int urgentClaimCount;
  final int pendingVerificationCount;
  final int approvedVerificationCount;
  final int rejectedVerificationCount;
  final int pendingUserApprovalCount;
  final int moderatedResourceCount;
  final int activeSystemDeliveryCount;
  final int totalMealsSaved;
  final int medicineKitsDistributed;

  factory RoleDashboardSummary.fromJson(Map<String, dynamic> json) {
    return RoleDashboardSummary(
      role: json['role']?.toString() ?? '',
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
      activeDonations: json['activeDonations'] as int? ?? 0,
      claimedDonations: json['claimedDonations'] as int? ?? 0,
      expiredDonations: json['expiredDonations'] as int? ?? 0,
      assignedDeliveryCount: json['assignedDeliveryCount'] as int? ?? 0,
      activeClaims: json['activeClaims'] as int? ?? 0,
      completedClaims: json['completedClaims'] as int? ?? 0,
      activeDeliveryCount: json['activeDeliveryCount'] as int? ?? 0,
      completedDeliveryCount: json['completedDeliveryCount'] as int? ?? 0,
      urgentClaimCount: json['urgentClaimCount'] as int? ?? 0,
      pendingVerificationCount: json['pendingVerificationCount'] as int? ?? 0,
      approvedVerificationCount: json['approvedVerificationCount'] as int? ?? 0,
      rejectedVerificationCount: json['rejectedVerificationCount'] as int? ?? 0,
      pendingUserApprovalCount: json['pendingUserApprovalCount'] as int? ?? 0,
      moderatedResourceCount: json['moderatedResourceCount'] as int? ?? 0,
      activeSystemDeliveryCount: json['activeSystemDeliveryCount'] as int? ?? 0,
      totalMealsSaved: json['totalMealsSaved'] as int? ?? 0,
      medicineKitsDistributed: json['medicineKitsDistributed'] as int? ?? 0,
    );
  }
}
