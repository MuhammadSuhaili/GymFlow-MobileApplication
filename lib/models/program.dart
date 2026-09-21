/// A workout program (e.g. "My Hypertrophy Program", 12 weeks).
class Program {
  final String id;
  final String name;
  final int durationWeeks;
  final String goal;
  final String? templateName;
  final bool isActive;
  final DateTime createdAt;

  const Program({
    required this.id,
    required this.name,
    required this.durationWeeks,
    required this.goal,
    this.templateName,
    required this.isActive,
    required this.createdAt,
  });

  Program copyWith({
    String? name,
    int? durationWeeks,
    String? goal,
    String? templateName,
    bool? isActive,
  }) {
    return Program(
      id: id,
      name: name ?? this.name,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      goal: goal ?? this.goal,
      templateName: templateName ?? this.templateName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  int get schedulePerWeek =>
      7; // Stored implicitly by the 7 workout days per week.

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'duration_weeks': durationWeeks,
        'goal': goal,
        'template_name': templateName,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Program.fromMap(Map<String, Object?> map) => Program(
        id: map['id'] as String,
        name: map['name'] as String,
        durationWeeks: (map['duration_weeks'] as num).toInt(),
        goal: map['goal'] as String,
        templateName: map['template_name'] as String?,
        isActive: (map['is_active'] as num?)?.toInt() == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}