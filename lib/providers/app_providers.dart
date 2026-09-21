import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/data/database/app_database.dart';
import 'package:gym_flow/data/repositories/checkin_repository.dart';
import 'package:gym_flow/data/repositories/exercise_repository.dart';
import 'package:gym_flow/data/repositories/measurement_repository.dart';
import 'package:gym_flow/data/repositories/program_repository.dart';
import 'package:gym_flow/data/repositories/settings_repository.dart';
import 'package:gym_flow/data/repositories/user_repository.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(appDatabaseProvider));
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository(ref.watch(appDatabaseProvider));
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(appDatabaseProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(appDatabaseProvider));
});

final checkinRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(appDatabaseProvider));
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

/// Bumping this counter forces dependent queries to re-run after mutations.
final refreshTriggerProvider =
    NotifierProvider<RefreshTrigger, int>(RefreshTrigger.new);

class RefreshTrigger extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Convenience: refresh the app data after any repository mutation.
final appRefreshProvider = Provider<RefreshCallback>((ref) {
  return RefreshCallback(ref);
});

class RefreshCallback {
  final Ref _ref;
  RefreshCallback(this._ref);

  void refresh() => _ref.read(refreshTriggerProvider.notifier).bump();

  Future<void> invalidateAllUserData() async {
    _ref.invalidate(userRepositoryProvider);
    _ref.invalidate(programRepositoryProvider);
    _ref.invalidate(workoutRepositoryProvider);
    _ref.invalidate(checkinRepositoryProvider);
    _ref.invalidate(measurementRepositoryProvider);
    _ref.invalidate(settingsRepositoryProvider);
    _ref.invalidate(refreshTriggerProvider);
  }
}