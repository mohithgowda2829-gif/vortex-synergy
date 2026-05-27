class AppValidators {
  static String? required(String? value, {String label = 'This field'}) {
    return value == null || value.trim().isEmpty ? '$label is required' : null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final RegExp pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(value.trim()) ? null : 'Enter a valid email address';
  }

  static String? phone(String? value, {String label = 'Phone'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final RegExp pattern = RegExp(r'^[0-9+\- ]{10,15}$');
    return pattern.hasMatch(value.trim()) ? null : 'Enter a valid phone number';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return value.length >= 8 ? null : 'Password must be at least 8 characters';
  }

  static String? wholeNumber(String? value, {String label = 'Value', int min = 1}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$label must be a whole number';
    }
    if (parsed < min) {
      return '$label must be at least $min';
    }
    return null;
  }

  static String? decimal(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.trim()) == null ? 'Enter a valid $label' : null;
  }
}
