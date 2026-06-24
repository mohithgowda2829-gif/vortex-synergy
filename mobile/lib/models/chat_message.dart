class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.claimId,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.message,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String claimId;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String message;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      claimId: json['claimId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      recipientId: json['recipientId']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      readAt: parseDate(json['readAt']),
    );
  }
}
