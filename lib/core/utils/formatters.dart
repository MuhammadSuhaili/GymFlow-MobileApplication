import 'package:intl/intl.dart';

/// Formatting helpers used across the app.
class Formatters {
  Formatters._();

  static final NumberFormat _weightFormat =
      NumberFormat.decimalPattern('en_US');

  static String weightKg(double? value) {
    if (value == null) return '--';
    return '${_weightFormat.format(value)} kg';
  }

  static String weightNum(double? value) {
    if (value == null) return '--';
    return _weightFormat.format(value);
  }

  static String volumeKg(double volume) {
    if (volume <= 0) return '0 kg';
    if (volume >= 1000) {
      return '${_weightFormat.format(volume / 1000)}t';
    }
    return '${_weightFormat.format(volume)} kg';
  }

  static String duration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String seconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String sleepDuration(int hours, int minutes) {
    if (hours == 0 && minutes == 0) return '--';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String percent(double value) => '${value.toStringAsFixed(1)}%';

  static String double1(double value) => value.toStringAsFixed(1);
}