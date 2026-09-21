/// An exercise from the library.
class Exercise {
  final String id;
  final String name;
  final String primaryMuscle;
  final String secondaryMuscle;
  final String equipment;
  final String difficulty;
  final String? instructions;
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.secondaryMuscle,
    required this.equipment,
    required this.difficulty,
    this.instructions,
    this.videoUrl,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'primary_muscle': primaryMuscle,
        'secondary_muscle': secondaryMuscle,
        'equipment': equipment,
        'difficulty': difficulty,
        'instructions': instructions,
        'video_url': videoUrl,
      };

  factory Exercise.fromMap(Map<String, Object?> map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        primaryMuscle: map['primary_muscle'] as String,
        secondaryMuscle: map['secondary_muscle'] as String,
        equipment: map['equipment'] as String,
        difficulty: map['difficulty'] as String,
        instructions: map['instructions'] as String?,
        videoUrl: map['video_url'] as String?,
      );
}

/// Maps an Exercise onto a workout day within the program.
///
/// Ships the user-defined target configuration (sets + rep range) that drives
/// the optional progressive-overload suggestions.
class ProgramDayExercise {
  final String id;
  final String workoutDayId;
  final String exerciseId;
  final int orderIndex;

  /// Target number of sets for this exercise (null until configured).
  final int? targetSets;

  /// Rep-range lower bound (null until configured).
  final int? minReps;

  /// Rep-range upper bound (null until configured).
  final int? maxReps;

  /// Optional user-defined starting weight (kg). Never enforced.
  final double? startingWeight;

  /// Optional per-exercise notes.
  final String? notes;

  const ProgramDayExercise({
    required this.id,
    required this.workoutDayId,
    required this.exerciseId,
    required this.orderIndex,
    this.targetSets,
    this.minReps,
    this.maxReps,
    this.startingWeight,
    this.notes,
  });

  ProgramDayExercise copyWith({
    int? targetSets,
    int? minReps,
    int? maxReps,
    double? startingWeight,
    Object? notes = _unset,
  }) {
    return ProgramDayExercise(
      id: id,
      workoutDayId: workoutDayId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      targetSets: targetSets ?? this.targetSets,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      startingWeight: startingWeight ?? this.startingWeight,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  static const Object _unset = Object();

  Map<String, Object?> toMap() => {
        'id': id,
        'workout_day_id': workoutDayId,
        'exercise_id': exerciseId,
        'order_index': orderIndex,
        'target_sets': targetSets,
        'min_reps': minReps,
        'max_reps': maxReps,
        'starting_weight': startingWeight,
        'notes': notes,
      };

  factory ProgramDayExercise.fromMap(Map<String, Object?> map) =>
      ProgramDayExercise(
        id: map['id'] as String,
        workoutDayId: map['workout_day_id'] as String,
        exerciseId: map['exercise_id'] as String,
        orderIndex: (map['order_index'] as num).toInt(),
        targetSets: (map['target_sets'] as num?)?.toInt(),
        minReps: (map['min_reps'] as num?)?.toInt(),
        maxReps: (map['max_reps'] as num?)?.toInt(),
        startingWeight: (map['starting_weight'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
      );
}