/// A single set within a workout session.
class WorkoutSet {
  final String id;
  final String sessionId;
  final String exerciseRefId;
  final String exerciseName;
  final int orderIndex;
  final double weight;
  final int reps;
  final int? rpe;
  final bool completed;

  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseRefId,
    required this.exerciseName,
    required this.orderIndex,
    required this.weight,
    required this.reps,
    this.rpe,
    this.completed = false,
  });

  WorkoutSet copyWith({
    String? sessionId,
    double? weight,
    int? reps,
    Object? rpe = _unset,
    bool? completed,
    int? orderIndex,
  }) {
    return WorkoutSet(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      exerciseRefId: exerciseRefId,
      exerciseName: exerciseName,
      orderIndex: orderIndex ?? this.orderIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: identical(rpe, _unset) ? this.rpe : rpe as int?,
      completed: completed ?? this.completed,
    );
  }

  static const Object _unset = Object();

  double get volume => weight * reps;

  Map<String, Object?> toMap() => {
        'id': id,
        'session_id': sessionId,
        'exercise_ref_id': exerciseRefId,
        'exercise_name': exerciseName,
        'order_index': orderIndex,
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
        'completed': completed ? 1 : 0,
      };

  factory WorkoutSet.fromMap(Map<String, Object?> map) => WorkoutSet(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        exerciseRefId: map['exercise_ref_id'] as String,
        exerciseName: map['exercise_name'] as String,
        orderIndex: (map['order_index'] as num).toInt(),
        weight: (map['weight'] as num).toDouble(),
        reps: (map['reps'] as num).toInt(),
        rpe: (map['rpe'] as num?)?.toInt(),
        completed: (map['completed'] as num?)?.toInt() == 1,
      );
}