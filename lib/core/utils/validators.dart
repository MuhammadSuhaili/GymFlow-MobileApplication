import 'package:flutter/foundation.dart';

/// Validators shared across forms. All return an error message or null.
class Validators {
  Validators._();

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return '$label cannot be negative';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return '$label must be greater than zero';
    }
    return null;
  }

  static String? positiveInt(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid whole number';
    }
    if (parsed <= 0) {
      return '$label must be at least 1';
    }
    return null;
  }

  static String? sleepHours(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sleep hours are required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 24) {
      return 'Hours must be between 0 and 24';
    }
    return null;
  }

  static String? sleepMinutes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sleep minutes are required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 59) {
      return 'Minutes must be between 0 and 59';
    }
    return null;
  }

  static String? optionalNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number for $label';
    }
    if (parsed < 0) {
      return '$label cannot be negative';
    }
    return null;
  }

  static void debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[GymFlow] $message');
    }
  }
}