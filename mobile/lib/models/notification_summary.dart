class NotificationSummary {
  const NotificationSummary({required this.unreadCount});

  final int unreadCount;

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
