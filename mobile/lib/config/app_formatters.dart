import 'package:intl/intl.dart';

String formatDateTime(DateTime? value) {
  if (value == null) return 'Not available';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value.toLocal());
}

String formatDate(DateTime? value) {
  if (value == null) return 'Not available';
  return DateFormat('dd MMM yyyy').format(value.toLocal());
}

String formatStatus(String value) {
  if (value.isEmpty) return 'Unknown';
  final String spaced = value.replaceAll('_', ' ').toLowerCase();
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String formatNotificationType(String value) {
  return formatStatus(value);
}
