/// Daily check-in record. Only one per day (editable on the same day).
class DailyCheckIn {
  final String id;
  final DateTime date;
  final int mood; // 1..5
  final int energy; // 1..5
  final int sleepHours;
  final int sleepMinutes;
  final int sleepQuality; // 1..5
  final int soreness; // 1..5
  final int motivation; // 1..5
  final double? weightKg;
  final String? notes;

  const DailyCheckIn({
    required this.id,
    required this.date,
    required this.mood,
    required this.energy,
    required this.sleepHours,
    required this.sleepMinutes,
    required this.sleepQuality,
    required this.soreness,
    required this.motivation,
    this.weightKg,
    this.notes,
  });

  DailyCheckIn copyWith({
    int? mood,
    int? energy,
    int? sleepHours,
    int? sleepMinutes,
    int? sleepQuality,
    int? soreness,
    int? motivation,
    double? weightKg,
    String? notes,
  }) {
    return DailyCheckIn(
      id: id,
      date: date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      soreness: soreness ?? this.soreness,
      motivation: motivation ?? this.motivation,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
    );
  }

  int get totalSleepMinutes => (sleepHours * 60) + sleepMinutes;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'mood': mood,
        'energy': energy,
        'sleep_hours': sleepHours,
        'sleep_minutes': sleepMinutes,
        'sleep_quality': sleepQuality,
        'soreness': soreness,
        'motivation': motivation,
        'weight_kg': weightKg,
        'notes': notes,
      };

  factory DailyCheckIn.fromMap(Map<String, Object?> map) => DailyCheckIn(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        mood: (map['mood'] as num).toInt(),
        energy: (map['energy'] as num).toInt(),
        sleepHours: (map['sleep_hours'] as num).toInt(),
        sleepMinutes: (map['sleep_minutes'] as num).toInt(),
        sleepQuality: (map['sleep_quality'] as num).toInt(),
        soreness: (map['soreness'] as num).toInt(),
        motivation: (map['motivation'] as num).toInt(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
      );
}