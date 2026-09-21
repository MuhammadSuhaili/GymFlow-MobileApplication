import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/exercises/exercise_detail_screen.dart';
import 'package:gym_flow/widgets/empty_state.dart';

/// Browse the exercise library with a muscle-group filter.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String? _muscle;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercises = ref.watch(exercisesProvider(_muscle));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search exercises…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _MuscleChip(
                  label: 'All',
                  selected: _muscle == null,
                  onTap: () => setState(() => _muscle = null),
                ),
                ...muscleGroups.map((m) => _MuscleChip(
                      label: m,
                      selected: _muscle == m,
                      onTap: () => setState(() => _muscle = m),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load: $e'),
              data: (list) {
                final filtered = _query.trim().isEmpty
                    ? list
                    : list
                        .where((e) => e.name
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No exercises found',
                    message: 'Try a different category or search term.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _ExerciseTile(item: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MuscleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise item;

  const _ExerciseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_muscleIcon(item.primaryMuscle),
                color: theme.colorScheme.primary),
          ),
          title: Text(item.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${item.primaryMuscle} • ${item.equipment} • ${item.difficulty}'),
          isThreeLine: false,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(exercise: item))),
        ),
      ),
    );
  }

  IconData _muscleIcon(String muscle) {
    switch (muscle) {
      case 'Chest':
        return Icons.expand_less_rounded;
      case 'Back':
        return Icons.view_week_rounded;
      case 'Shoulder':
        return Icons.panorama_vertical_rounded;
      case 'Biceps':
      case 'Triceps':
        return Icons.rotate_90_degrees_ccw_rounded;
      case 'Legs':
        return Icons.directions_walk_rounded;
      case 'Glutes':
        return Icons.airline_seat_recline_normal_rounded;
      case 'Core':
        return Icons.square_foot_rounded;
      case 'Cardio':
        return Icons.favorite_rounded;
      default:
        return Icons.sports_gymnastics_rounded;
    }
  }
}