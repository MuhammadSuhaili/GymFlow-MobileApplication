/// A single week belonging to a program.
class ProgramWeek {
  final String id;
  final String programId;
  final int weekNumber;
  final int monthNumber;
  final String name;

  const ProgramWeek({
    required this.id,
    required this.programId,
    required this.weekNumber,
    required this.monthNumber,
    required this.name,
  });

  ProgramWeek copyWith({String? name}) => ProgramWeek(
        id: id,
        programId: programId,
        weekNumber: weekNumber,
        monthNumber: monthNumber,
        name: name ?? this.name,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'program_id': programId,
        'week_number': weekNumber,
        'month_number': monthNumber,
        'name': name,
      };

  factory ProgramWeek.fromMap(Map<String, Object?> map) => ProgramWeek(
        id: map['id'] as String,
        programId: map['program_id'] as String,
        weekNumber: (map['week_number'] as num).toInt(),
        monthNumber: (map['month_number'] as num).toInt(),
        name: map['name'] as String,
      );

  static String defaultName(int weekNumber) => 'Week $weekNumber';

  static int monthFor(int weekNumber) => ((weekNumber - 1) ~/ 4) + 1;
}