import 'dart:convert';

import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/workout_set.dart';

/// An in-progress workout that can be resumed if the app is closed
/// accidentally.
class WorkoutDraft {
  final String id;
  final String? programId;
  final String? workoutDayId;
  final String title;
  final DateTime startedAt;
  final List<Exercise> exercises;
  final Map<String, List<WorkoutSet>> sets;
  final int currentIndex;
  final String notes;

  const WorkoutDraft({
    required this.id,
    this.programId,
    this.workoutDayId,
    required this.title,
    required this.startedAt,
    required this.exercises,
    required this.sets,
    required this.currentIndex,
    this.notes = '',
  });

  WorkoutDraft copyWith({
    DateTime? startedAt,
    List<Exercise>? exercises,
    Map<String, List<WorkoutSet>>? sets,
    int? currentIndex,
    String? notes,
  }) {
    return WorkoutDraft(
      id: id,
      programId: programId,
      workoutDayId: workoutDayId,
      title: title,
      startedAt: startedAt ?? this.startedAt,
      exercises: exercises ?? this.exercises,
      sets: sets ?? this.sets,
      currentIndex: currentIndex ?? this.currentIndex,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'program_id': programId,
        'workout_day_id': workoutDayId,
        'title': title,
        'started_at': startedAt.toIso8601String(),
        'data': jsonEncode({
          'exercises': exercises.map((e) => e.toMap()).toList(),
          'sets': sets.map(
              (k, v) => MapEntry(k, v.map((s) => s.toMap()).toList())),
          'index': currentIndex,
          'notes': notes,
        }),
      };

  factory WorkoutDraft.fromMap(Map<String, Object?> map) {
    final data = jsonDecode(map['data'] as String) as Map<String, dynamic>;
    return WorkoutDraft(
      id: map['id'] as String,
      programId: map['program_id'] as String?,
      workoutDayId: map['workout_day_id'] as String?,
      title: map['title'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      exercises: (data['exercises'] as List)
          .map((e) => Exercise.fromMap((e as Map).cast<String, Object?>()))
          .toList(),
      sets: (data['sets'] as Map<String, dynamic>).map((k, v) => MapEntry(
          k,
          (v as List)
              .map((s) =>
                  WorkoutSet.fromMap((s as Map).cast<String, Object?>()))
              .toList())),
      currentIndex: data['index'] as int,
      notes: data['notes'] as String? ?? '',
    );
  }
}