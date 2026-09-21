/// A notification reminder setting (workout, check-in, rest, schedule).
enum NotificationType {
  workout,
  dailyCheckIn,
  rest,
  schedule;
}

class NotificationSetting {
  final String id;
  final NotificationType type;
  final bool enabled;
  final int hour;
  final int minute;
  final String? label;

  const NotificationSetting({
    required this.id,
    required this.type,
    required this.enabled,
    required this.hour,
    required this.minute,
    this.label,
  });

  String get title {
    switch (type) {
      case NotificationType.workout:
        return label ?? 'Workout Reminder';
      case NotificationType.dailyCheckIn:
        return label ?? 'Daily Check-in';
      case NotificationType.rest:
        return label ?? 'Rest Day';
      case NotificationType.schedule:
        return label ?? 'Program Schedule';
    }
  }

  String get description {
    switch (type) {
      case NotificationType.workout:
        return 'Remind me before my workout';
      case NotificationType.dailyCheckIn:
        return 'Remind me to do my daily check-in';
      case NotificationType.rest:
        return 'Remember to recover on rest days';
      case NotificationType.schedule:
        return 'Show today\'s program schedule';
    }
  }

  NotificationSetting copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return NotificationSetting(
      id: id,
      type: type,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'enabled': enabled ? 1 : 0,
        'hour': hour,
        'minute': minute,
        'label': label,
      };

  factory NotificationSetting.fromMap(Map<String, Object?> map) =>
      NotificationSetting(
        id: map['id'] as String,
        type: NotificationType.values.firstWhere(
          (t) => t.name == map['type'],
        ),
        enabled: (map['enabled'] as num?)?.toInt() == 1,
        hour: (map['hour'] as num).toInt(),
        minute: (map['minute'] as num).toInt(),
        label: map['label'] as String?,
      );
}