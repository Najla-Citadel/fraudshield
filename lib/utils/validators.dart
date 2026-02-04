// lib/utils/validators.dart
class Validators {
  // ============================================
  // PHONE NUMBER VALIDATION
  // ============================================
  
  /// Validates Malaysian phone numbers
  /// Accepts formats: +60123456789, 0123456789, 012-3456789
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Malaysian phone number patterns
    // Mobile: +60123456789 or 0123456789 (10-11 digits starting with 01)
    // Landline: +6031234567 or 031234567 (9-10 digits starting with 03-09)
    final mobilePattern = RegExp(r'^(\+?60|0)1[0-9]{8,9}$');
    final landlinePattern = RegExp(r'^(\+?60|0)[3-9][0-9]{7,8}$');

    if (!mobilePattern.hasMatch(cleaned) && !landlinePattern.hasMatch(cleaned)) {
      return 'Invalid Malaysian phone number format';
    }

    return null;
  }

  /// Sanitizes phone number by removing special characters
  static String sanitizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // ============================================
  // URL VALIDATION
  // ============================================
  
  /// Validates URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    // Basic URL pattern
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlPattern.hasMatch(value)) {
      return 'Invalid URL format';
    }

    return null;
  }

  /// Sanitizes URL by trimming and lowercasing
  static String sanitizeUrl(String value) {
    return value.trim().toLowerCase();
  }

  // ============================================
  // BANK ACCOUNT VALIDATION
  // ============================================
  
  /// Validates bank account number
  /// Malaysian bank accounts are typically 10-16 digits
  static String? validateBankAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bank account number is required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Bank account must contain only numbers';
    }

    // Check length (Malaysian bank accounts: 10-16 digits)
    if (cleaned.length < 10 || cleaned.length > 16) {
      return 'Bank account must be 10-16 digits';
    }

    return null;
  }

  /// Sanitizes bank account by removing special characters
  static String sanitizeBankAccount(String value) {
    return value.replaceAll(RegExp(r'[\s\-]'), '');
  }

  // ============================================
  // GENERAL INPUT SANITIZATION
  // ============================================
  
  /// Removes potentially dangerous characters from input
  /// Prevents basic XSS and SQL injection attempts
  static String sanitizeInput(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[<>"''%;()&+]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailPattern.hasMatch(value)) {
      return 'Invalid email format';
    }

    return null;
  }

  /// Validates password strength
  /// Requires: min 8 chars, 1 uppercase, 1 lowercase, 1 number
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates non-empty text
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }
}
