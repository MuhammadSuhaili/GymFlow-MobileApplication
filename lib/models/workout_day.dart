/// A single day of a program week (7 days: Monday..Sunday).
/// A day is either a rest day or a workout day with a title.
class WorkoutDay {
  final String id;
  final String programId;
  final String weekId;
  final int dayOfWeek; // 1 = Monday .. 7 = Sunday
  final String title;
  final bool isRest;

  const WorkoutDay({
    required this.id,
    required this.programId,
    required this.weekId,
    required this.dayOfWeek,
    required this.title,
    required this.isRest,
  });

  WorkoutDay copyWith({
    String? id,
    String? weekId,
    String? title,
    bool? isRest,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      programId: programId,
      weekId: weekId ?? this.weekId,
      dayOfWeek: dayOfWeek,
      title: title ?? this.title,
      isRest: isRest ?? this.isRest,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'program_id': programId,
        'week_id': weekId,
        'day_of_week': dayOfWeek,
        'title': title,
        'is_rest': isRest ? 1 : 0,
      };

  factory WorkoutDay.fromMap(Map<String, Object?> map) => WorkoutDay(
        id: map['id'] as String,
        programId: map['program_id'] as String,
        weekId: map['week_id'] as String,
        dayOfWeek: (map['day_of_week'] as num).toInt(),
        title: map['title'] as String,
        isRest: (map['is_rest'] as num?)?.toInt() == 1,
      );

  /// Convenience: build a derivative day with a new id when editing a week.
  WorkoutDay copyWithNewId(String newId, {String? weekId, String? title, bool? isRest}) => copyWith(
        id: newId,
        weekId: weekId ?? this.weekId,
        title: title ?? this.title,
        isRest: isRest ?? this.isRest,
      );
}