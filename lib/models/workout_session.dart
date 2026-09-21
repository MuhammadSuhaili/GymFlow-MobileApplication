/// A completed (recorded) workout session.
class WorkoutSession {
  final String id;
  final String? programId;
  final String? workoutDayId;
  final String title;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String status; // completed | missed | cancelled
  final String? notes;
  final double totalVolumeKg;

  const WorkoutSession({
    required this.id,
    this.programId,
    this.workoutDayId,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.status = 'completed',
    this.notes,
    this.totalVolumeKg = 0,
  });

  WorkoutSession copyWith({
    DateTime? date,
    DateTime? endTime,
    int? durationMinutes,
    String? status,
    Object? notes = _unset,
    double? totalVolumeKg,
  }) {
    return WorkoutSession(
      id: id,
      programId: programId,
      workoutDayId: workoutDayId,
      title: title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
    );
  }

  static const Object _unset = Object();

  Map<String, Object?> toMap() => {
        'id': id,
        'program_id': programId,
        'workout_day_id': workoutDayId,
        'title': title,
        'date': date.isoDateTimeLocal,
        'start_time': startTime?.isoDateTimeLocal,
        'end_time': endTime?.isoDateTimeLocal,
        'duration_minutes': durationMinutes,
        'status': status,
        'notes': notes,
        'total_volume_kg': totalVolumeKg,
      };

  factory WorkoutSession.fromMap(Map<String, Object?> map) =>
      WorkoutSession(
        id: map['id'] as String,
        programId: map['program_id'] as String?,
        workoutDayId: map['workout_day_id'] as String?,
        title: map['title'] as String,
        date: DateTime.parse(map['date'] as String),
        startTime: map['start_time'] == null
            ? null
            : DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] == null
            ? null
            : DateTime.parse(map['end_time'] as String),
        durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
        status: map['status'] as String? ?? 'completed',
        notes: map['notes'] as String?,
        totalVolumeKg: (map['total_volume_kg'] as num?)?.toDouble() ?? 0,
      );
}

extension on DateTime {
  String get isoDateTimeLocal => toIso8601String();
}