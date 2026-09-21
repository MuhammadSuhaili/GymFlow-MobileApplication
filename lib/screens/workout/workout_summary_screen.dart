import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/workout_session.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:gym_flow/providers/app_providers.dart';

/// Post-workout summary with stats and optional notes.
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;
  final List<WorkoutSet> sets;
  final List<Exercise> exercises;
  final int totalReps;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.sets,
    required this.exercises,
    required this.totalReps,
  });

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  Future<void> _addNotes() async {
    final controller = TextEditingController(text: widget.session.notes ?? '');
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Notes'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Form felt great today.\nLast set was heavy.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (notes == null) return;
    final updated = widget.session.copyWith(notes: notes.isEmpty ? null : notes);
    await ref.read(workoutRepositoryProvider).updateSession(updated);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notes saved'),
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedSets =
        widget.sets.where((s) => s.completed).length;
    final exerciseCount = widget.exercises.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successSoft,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              Text('Workout Complete',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(widget.session.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: Formatters.duration(
                              widget.session.durationMinutes)),
                      const Divider(),
                      _SummaryRow(
                          icon: Icons.fitness_center_rounded,
                          label: 'Exercises',
                          value: '$exerciseCount'),
                      const Divider(),
                      _SummaryRow(
                          icon: Icons.list_alt_rounded,
                          label: 'Completed Sets',
                          value: '$completedSets'),
                      const Divider(),
                      _SummaryRow(
                          icon: Icons.straighten_rounded,
                          label: 'Total Volume',
                          value:
                              Formatters.volumeKg(widget.session.totalVolumeKg)),
                      const Divider(),
                      _SummaryRow(
                          icon: Icons.repeat_rounded,
                          label: 'Total Reps',
                          value: '${widget.totalReps}'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _addNotes,
                icon: const Icon(Icons.sticky_note_2_outlined),
                label: const Text('Add Workout Notes'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}