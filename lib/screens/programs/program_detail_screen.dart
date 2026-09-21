import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/program.dart';
import 'package:gym_flow/models/program_week.dart';
import 'package:gym_flow/models/workout_day.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/exercises/exercise_picker_screen.dart';
import 'package:gym_flow/screens/programs/week_schedule_editor_screen.dart';
import 'package:gym_flow/widgets/app_card.dart';
import 'package:gym_flow/widgets/empty_state.dart';
import 'package:gym_flow/widgets/exercise_config_dialog.dart';

/// Program overview with weekly schedule and daily exercises.
class ProgramDetailScreen extends ConsumerStatefulWidget {
  final Program program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  late String _selectedWeekId;

  @override
  void initState() {
    super.initState();
    _selectedWeekId = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = ref.watch(programWeeksProvider(widget.program.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded),
            tooltip: 'Edit weekly schedule',
            onPressed: () {
              final weekId = _selectedWeekId.isEmpty
                  ? weeks.valueOrNull?.first.id
                  : _selectedWeekId;
              if (weekId == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WeekScheduleEditorScreen(
                    programId: widget.program.id,
                    weekId: weekId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: weeks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (weekList) {
          if (weekList.isEmpty) {
            return const EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No weeks configured',
              message: 'This program has no weeks.',
            );
          }
          if (_selectedWeekId.isEmpty) _selectedWeekId = weekList.first.id;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeaderCard(program: widget.program),
              const SizedBox(height: 16),
              _ProgramIntelligenceCard(program: widget.program),
              const SizedBox(height: 16),
              Text(
                'Weekly Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: weekList.map((week) {
                    final selected = week.id == _selectedWeekId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(week.name),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedWeekId = week.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              for (final week in weekList)
                if (week.id == _selectedWeekId)
                  _WeekDaysList(programId: widget.program.id, week: week),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Program program;

  const _HeaderCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderStat(
                icon: Icons.calendar_month_rounded,
                label: 'Duration',
                value: '${program.durationWeeks} weeks',
              ),
              const SizedBox(width: 20),
              _HeaderStat(
                icon: Icons.flag_rounded,
                label: 'Goal',
                value: program.goal,
              ),
              const SizedBox(width: 20),
              _HeaderStat(
                icon: Icons.repeat_rounded,
                label: 'Schedule',
                value: '${(program.durationWeeks / 4).ceil()} months',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Program intelligence: current week, today's workout, weekly completion and
/// which scheduled exercises already have previous-performance data.
class _ProgramIntelligenceCard extends ConsumerWidget {
  final Program program;

  const _ProgramIntelligenceCard({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final intelligence = ref.watch(programIntelligenceProvider(program));

    return AppCard(
      child: intelligence.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const SizedBox.shrink(),
        data: (info) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Program',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.event_repeat_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Week ${info.currentWeekNumber} of ${info.durationWeeks}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Today: ${info.todayTitle}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Workouts this week',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${info.completedThisWeek} / ${info.weeklyTarget} '
                  'completed • ${info.remainingThisWeek} remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: info.weeklyTarget == 0
                    ? 0
                    : (info.completedThisWeek / info.weeklyTarget).clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            if (info.exercisesWithProgress.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Exercises with progression data',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: info.exercisesWithProgress.take(6).map((e) {
                  final prev = e.previousBestWeight != null
                      ? '${_weightNum(e.previousBestWeight!)} kg × '
                            '${e.previousBestReps}'
                      : null;
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    label: Text(
                      prev == null
                          ? e.exerciseName
                          : '${e.exerciseName} — $prev',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _weightNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _WeekDaysList extends ConsumerWidget {
  final String programId;
  final ProgramWeek week;

  const _WeekDaysList({required this.programId, required this.week});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(weekDaysProvider(week.id));
    return days.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Failed: $e'),
      data: (dayList) {
        if (dayList.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'No schedule',
            message: 'Edit this week to add a schedule.',
          );
        }
        return Column(
          children: dayList.map((day) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayTile(programId: programId, day: day),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DayTile extends ConsumerWidget {
  final String programId;
  final WorkoutDay day;

  const _DayTile({required this.programId, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(dayExercisesProvider(day.id));
    final isRest = day.isRest;

    return AppCard(
      onTap: () => _showDaySheet(context, ref, day),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isRest
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      day.dayOfWeek.weekdayShort,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isRest
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.dayOfWeek.dayOfWeekFull,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      isRest ? 'Rest' : day.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isRest
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    exercises.when(
                      loading: () => const SizedBox(height: 10),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (list) => isRest
                          ? const SizedBox.shrink()
                          : Text(
                              '${list.length} exercises',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              if (!isRest)
                exercises.when(
                  data: (list) => Text(
                    list.length.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDaySheet(
    BuildContext context,
    WidgetRef ref,
    WorkoutDay day,
  ) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _DaySheet(
          day: day,
          programId: programId,
          scrollController: scrollController,
        ),
      ),
    );
    ref.read(refreshTriggerProvider.notifier).bump();
  }
}

class _DaySheet extends ConsumerWidget {
  final WorkoutDay day;
  final String programId;
  final ScrollController? scrollController;

  const _DaySheet({
    required this.day,
    required this.programId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(dayExercisesProvider(day.id));
    final configs = ref.watch(dayExerciseConfigsProvider(day.id));
    final repo = ref.watch(programRepositoryProvider);

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.dayOfWeek.dayOfWeekFull} — ${day.isRest ? 'Rest' : day.title}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.isRest
                ? 'Rest day. No exercises scheduled.'
                : 'Tap an exercise to set its target sets and rep range.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!day.isRest)
            exercises.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                ProgramDayExercise? configFor(Exercise e) {
                  for (final c in configs.valueOrNull ?? const []) {
                    if (c.exerciseId == e.id) return c;
                  }
                  return null;
                }

                String? subtitleFor(ProgramDayExercise? config) {
                  if (config == null ||
                      config.minReps == null ||
                      config.maxReps == null) {
                    return null;
                  }
                  final min = config.minReps;
                  final max = config.maxReps;
                  final setsPart = config.targetSets != null
                      ? '${config.targetSets} sets × '
                      : '';
                  final startPart = config.startingWeight != null
                      ? ' • start ${_weightNum(config.startingWeight!)} kg'
                      : '';
                  return '$setsPart$min–$max reps$startPart';
                }

                return list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No exercises yet.'),
                      )
                    : Column(
                        children: list.map((e) {
                          final config = configFor(e);
                          final subtitle = subtitleFor(config);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(
                              Icons.fitness_center_rounded,
                              size: 20,
                            ),
                            title: Text(
                              e.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: subtitle == null
                                ? Text(
                                    'No rep range set',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                            onTap: () => _configureExercise(
                              context,
                              ref,
                              e,
                              config ??
                                  ProgramDayExercise(
                                    id: '',
                                    workoutDayId: day.id,
                                    exerciseId: e.id,
                                    orderIndex: 0,
                                  ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              onPressed: () async {
                                await repo.removeExerciseFromDay(day.id, e.id);
                                if (context.mounted) {
                                  ref
                                      .read(refreshTriggerProvider.notifier)
                                      .bump();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!day.isRest) ...[
                TextButton.icon(
                  onPressed: () => _openPicker(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercises'),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              TextButton.icon(
                onPressed: () => _editDay(context, ref),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(day.isRest ? 'Set as Workout' : 'Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _configureExercise(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
    ProgramDayExercise config,
  ) async {
    final updated = await showDialog<ProgramDayExercise>(
      context: context,
      builder: (_) =>
          ExerciseConfigDialog(exerciseName: exercise.name, initial: config),
    );
    if (updated == null || updated.id.isEmpty) return;
    final repo = ref.read(programRepositoryProvider);
    await repo.updateExerciseConfig(updated);
    ref.read(refreshTriggerProvider.notifier).bump();
  }

  String _weightNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(programRepositoryProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercisePickerScreen(
          alreadyAdded:
              ref
                  .read(dayExercisesProvider(day.id))
                  .valueOrNull
                  ?.map((e) => e.id)
                  .toList() ??
              [],
          onConfirm: (selected) => repo.addExercisesToDay(
            day.id,
            selected.map((e) => e.id).toList(),
          ),
        ),
      ),
    );
    ref.read(refreshTriggerProvider.notifier).bump();
  }

  Future<void> _editDay(BuildContext context, WidgetRef ref) async {
    var isRest = day.isRest;
    var title = workoutTitles.contains(day.title)
        ? day.title
        : (day.isRest ? workoutTitles.first : day.title);
    final options = [
      ...workoutTitles,
      if (day.title.isNotEmpty &&
          day.title != 'Rest' &&
          !workoutTitles.contains(day.title))
        day.title,
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rest day'),
                value: isRest,
                onChanged: (v) => setDialogState(() => isRest = v),
              ),
              if (!isRest)
                DropdownButtonFormField<String>(
                  initialValue: options.contains(title) ? title : options.first,
                  decoration: const InputDecoration(labelText: 'Workout title'),
                  items: options
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => title = v ?? title),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final repo = ref.read(programRepositoryProvider);
      await repo.updateDay(
        day.copyWith(title: isRest ? 'Rest' : title, isRest: isRest),
      );
      ref.read(refreshTriggerProvider.notifier).bump();
    }
  }
}
