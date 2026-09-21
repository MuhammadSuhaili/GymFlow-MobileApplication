/// A body measurement snapshot taken over time.
class BodyMeasurement {
  final String id;
  final DateTime date;
  final double? weightKg;
  final double? bodyFat;
  final double? chestCm;
  final double? waistCm;
  final double? armCm;
  final double? thighCm;
  final double? hipsCm;
  final String? notes;
  final DateTime? createdAt;

  const BodyMeasurement({
    required this.id,
    required this.date,
    this.weightKg,
    this.bodyFat,
    this.chestCm,
    this.waistCm,
    this.armCm,
    this.thighCm,
    this.hipsCm,
    this.notes,
    this.createdAt,
  });

  BodyMeasurement copyWith({
    double? weightKg,
    double? bodyFat,
    double? chestCm,
    double? waistCm,
    double? armCm,
    double? thighCm,
    double? hipsCm,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id,
      date: date,
      weightKg: weightKg ?? this.weightKg,
      bodyFat: bodyFat ?? this.bodyFat,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      armCm: armCm ?? this.armCm,
      thighCm: thighCm ?? this.thighCm,
      hipsCm: hipsCm ?? this.hipsCm,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'weight_kg': weightKg,
        'body_fat': bodyFat,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'arm_cm': armCm,
        'thigh_cm': thighCm,
        'hips_cm': hipsCm,
        'notes': notes,
        'created_at': createdAt?.toIso8601String(),
      };

  factory BodyMeasurement.fromMap(Map<String, Object?> map) =>
      BodyMeasurement(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        bodyFat: (map['body_fat'] as num?)?.toDouble(),
        chestCm: (map['chest_cm'] as num?)?.toDouble(),
        waistCm: (map['waist_cm'] as num?)?.toDouble(),
        armCm: (map['arm_cm'] as num?)?.toDouble(),
        thighCm: (map['thigh_cm'] as num?)?.toDouble(),
        hipsCm: (map['hips_cm'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.tryParse(map['created_at'] as String),
      );
}