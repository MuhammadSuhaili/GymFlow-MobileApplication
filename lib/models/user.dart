/// Represents the app user profile.
class User {
  final String id;
  final String name;
  final int age;
  final double heightCm;
  final double weightKg;
  final String goal;
  final String experience;
  final String unitSystem;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.experience,
    required this.unitSystem,
    required this.createdAt,
  });

  factory User.defaults() => User(
        id: 'default-user',
        name: 'Athlete',
        age: 25,
        heightCm: 175,
        weightKg: 72.0,
        goal: 'Muscle Building',
        experience: 'Beginner',
        unitSystem: 'Metric (kg)',
        createdAt: DateTime.now(),
      );

  User copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    String? goal,
    String? experience,
    String? unitSystem,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      unitSystem: unitSystem ?? this.unitSystem,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'goal': goal,
        'experience': experience,
        'unit_system': unitSystem,
        'created_at': createdAt.toIso8601String(),
      };

  factory User.fromMap(Map<String, Object?> map) => User(
        id: map['id'] as String,
        name: map['name'] as String,
        age: (map['age'] as num).toInt(),
        heightCm: (map['height_cm'] as num).toDouble(),
        weightKg: (map['weight_kg'] as num).toDouble(),
        goal: map['goal'] as String,
        experience: map['experience'] as String,
        unitSystem: map['unit_system'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}