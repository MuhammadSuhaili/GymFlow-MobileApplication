import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/data/repositories/program_repository.dart';
import 'package:gym_flow/data/repositories/user_repository.dart';
import 'package:gym_flow/data/repositories/workout_repository.dart';

/// Builds a short summary of the user's profile and progress, sent to Aira as
/// context so answers are personalized to the GymFlow user.
class AiraContextService {
  AiraContextService({
    required this._users,
    required this._programs,
    required this._workouts,
  });

  final UserRepository _users;
  final ProgramRepository _programs;
  final WorkoutRepository _workouts;

  Future<String> build() async {
    final parts = <String>[];

    final user = await _users.getUser();
    parts.add(
      'PROFIL PENGGUNA: ${user.name}, ${user.age} tahun, '
      '${user.heightCm} cm / ${user.weightKg} kg, '
      'tujuan: ${user.goal}, tingkat pengalaman: ${user.experience}.',
    );

    final program = await _programs.getActiveProgram();
    if (program != null) {
      parts.add(
        'PROGRAM AKTIF: "${program.name}" (${program.durationWeeks} minggu, '
        'goal program: ${program.goal}).',
      );
    }

    final recent = await _workouts.getHistoryWithStats(limit: 5);
    if (recent.isNotEmpty) {
      final lines = recent.map((h) {
        final w = h.session;
        return '- ${w.date.displayShort}: ${w.title}, ${w.durationMinutes} '
            'menit, ${h.completedSets} set, volume '
            '${Formatters.volumeKg(w.totalVolumeKg)}';
      }).join('\n');
      parts.add('5 LATIHAN TERAKHIR:\n$lines');
    }

    return parts.join('\n\n');
  }
}