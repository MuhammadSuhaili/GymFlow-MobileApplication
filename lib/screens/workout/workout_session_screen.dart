import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/workout_draft.dart';
import 'package:gym_flow/models/workout_session.dart';
import 'package:gym_flow/models/workout_set.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/workout/workout_summary_screen.dart';
import 'package:gym_flow/services/progression_service.dart';
import 'package:gym_flow/widgets/rest_timer_sheet.dart';
import 'package:uuid/uuid.dart';

/// Active workout session: one exercise at a time, logs sets/reps/weight,
/// shows previous performance, rest timer, notes and finish flow.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String programId;
  final String workoutDayId;
  final String title;

  const WorkoutSessionScreen({
    super.key,
    required this.programId,
    required this.workoutDayId,
    required this.title,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  final _uuid = const Uuid();

  DateTime _startedAt = DateTime.now();
  String _draftId = '';
  List<Exercise> _exercises = [];
  final Map<String, List<WorkoutSet>> _sets = {};
  int _index = 0;
  String _notes = '';

  bool _loading = true;
  bool _finishing = false;

  Timer? _elapsedTimer;
  Timer? _draftTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _draftId = _uuid.v4();
    _load();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt));
      }
    });
  }

  Future<void> _load() async {
    final repo = ref.read(programRepositoryProvider);
    final exercises = await repo.getExercisesForDay(widget.workoutDayId);
    final draftDatum = await ref
        .read(workoutRepositoryProvider)
        .getDraftForDay(widget.workoutDayId);
    if (!mounted) return;
    setState(() {
      if (draftDatum != null && draftDatum.exercises.isNotEmpty) {
        _draftId = draftDatum.id;
        _startedAt = draftDatum.startedAt;
        _exercises = draftDatum.exercises;
        _sets..clear()..addAll(draftDatum.sets);
        _index = draftDatum.currentIndex.clamp(0, _exercises.length - 1);
        _notes = draftDatum.notes;
      } else {
        _exercises = exercises;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _draftTimer?.cancel();
    unawaited(_persistDraft());
    super.dispose();
  }

  // ---- Set operations ----

  void _addSet(Exercise exercise, {double weight = 0, int reps = 10}) {
    final current = _sets[exercise.id] ?? [];
    final set = WorkoutSet(
      id: _uuid.v4(),
      sessionId: _draftId,
      exerciseRefId: exercise.id,
      exerciseName: exercise.name,
      orderIndex: _sets[exercise.id]?.length ?? 0,
      weight: weight,
      reps: reps,
    );
    setState(() {
      final list = List<WorkoutSet>.from(current)..add(set);
      _sets[exercise.id] = list;
    });
    _scheduleDraftSave();
  }

  void _updateSet(Exercise exercise, WorkoutSet updated) {
    final current = List<WorkoutSet>.from(_sets[exercise.id] ?? []);
    final index = current.indexWhere((s) => s.id == updated.id);
    if (index >= 0) current[index] = updated;
    setState(() => _sets[exercise.id] = current);
    _scheduleDraftSave();
  }

  void _deleteSet(Exercise exercise, String setId) {
    final current = List<WorkoutSet>.from(_sets[exercise.id] ?? []);
    current.removeWhere((s) => s.id == setId);
    setState(() => _sets[exercise.id] = current);
    _scheduleDraftSave();
  }

  /// Completes the first incomplete set. Returns the completed set when the
  /// set has a weight, otherwise null.
  WorkoutSet? _completeNextSet(Exercise exercise) {
    final current = List<WorkoutSet>.from(_sets[exercise.id] ?? []);
    for (var i = 0; i < current.length; i++) {
      if (!current[i].completed) {
        if (current[i].weight <= 0) return null;
        final completed = current[i].copyWith(completed: true);
        current[i] = completed;
        setState(() => _sets[exercise.id] = current);
        _scheduleDraftSave();
        return completed;
      }
    }
    return null;
  }

  // ---- Draft persistence ----

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft() async {
    if (_loading) return;
    final draft = WorkoutDraft(
      id: _draftId,
      programId: widget.programId,
      workoutDayId: widget.workoutDayId,
      title: widget.title,
      startedAt: _startedAt,
      exercises: _exercises,
      sets: Map.of(_sets),
      currentIndex: _index,
      notes: _notes,
    );
    try {
      await ref.read(workoutRepositoryProvider).saveDraft(draft);
    } catch (_) {}
  }

  // ---- Navigation ----

  bool get _isLastExercise => _index >= _exercises.length - 1;

  bool _exerciseDone(Exercise exercise) {
    final sets = _sets[exercise.id] ?? const [];
    return sets.isNotEmpty && sets.every((s) => s.completed);
  }

  int get _doneCount => _exercises.where(_exerciseDone).length;

  void _goPrevious() {
    FocusScope.of(context).unfocus();
    if (_index > 0) {
      setState(() => _index--);
      _scheduleDraftSave();
    }
  }

  Future<void> _goNext() async {
    FocusScope.of(context).unfocus();
    final exercise = _exercises[_index];
    final sets = _sets[exercise.id] ?? const [];
    if (!_exerciseDone(exercise)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move to next exercise?'),
          content: sets.isEmpty
              ? const Text('No sets logged for this exercise yet.')
              : const Text('This exercise still has incomplete sets. '
                  'You can come back later.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!_isLastExercise) {
      setState(() => _index++);
      _scheduleDraftSave();
    }
  }

  // ---- Finish ----

  Future<bool?> _confirmFinish({required bool hasIncomplete}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish workout?'),
        content: hasIncomplete
            ? const Text('Some sets are still marked as not completed. '
                'Finish anyway?')
            : const Text('Save this workout and see your summary.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(hasIncomplete ? 'Finish Anyway' : 'Finish')),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    FocusScope.of(context).unfocus();
    final allSets = _sets.values.expand((s) => s).toList();
    if (allSets.isEmpty) {
      _snack('Add at least one set before finishing.');
      return;
    }
    final hasIncomplete = allSets.any((s) => !s.completed);
    final confirmed = await _confirmFinish(hasIncomplete: hasIncomplete);
    if (confirmed != true) return;

    setState(() => _finishing = true);
    var volume = 0.0;
    var totalReps = 0;
    for (final s in allSets) {
      if (s.completed && s.reps > 0) {
        volume += s.weight * s.reps;
        totalReps += s.reps;
      }
    }
    final now = DateTime.now();
    final session = WorkoutSession(
      id: _draftId,
      programId: widget.programId,
      workoutDayId: widget.workoutDayId,
      title: widget.title,
      date: now,
      startTime: _startedAt,
      endTime: now,
      durationMinutes: now.difference(_startedAt).inMinutes,
      status: 'completed',
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
      totalVolumeKg: volume,
    );
    final sets = allSets
        .map((s) => s.copyWith(
            orderIndex: allSets.indexOf(s), sessionId: _draftId))
        .toList();
    final repo = ref.read(workoutRepositoryProvider);
    await repo.saveSession(session, sets);
    await repo.clearDraft(_draftId);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(
        session: session,
        sets: sets,
        exercises: _exercises,
        totalReps: totalReps,
      ),
    ));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _startRest() async => RestTimerSheet.show(context);

  Future<void> _editNotes() async {
    final controller = TextEditingController(text: _notes);
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
            hintText: 'Good session today.\nLast set was heavy.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (notes == null) return;
    setState(() => _notes = notes);
    _scheduleDraftSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Elapsed ${Formatters.seconds(_elapsed.inSeconds)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _editNotes,
            icon: const Icon(Icons.sticky_note_2_outlined),
            tooltip: 'Workout notes',
          ),
          IconButton(
            onPressed: _startRest,
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Rest timer',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading || _exercises.isEmpty
              ? FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('Finish Workout'))
              : Row(
                  children: [
                    if (_index > 0)
                      IconButton.filledTonal(
                        onPressed: _goPrevious,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Previous exercise',
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _finishing
                            ? null
                            : _isLastExercise
                                ? _finish
                                : _goNext,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                        icon: Icon(_isLastExercise
                            ? Icons.flag_rounded
                            : Icons.arrow_forward_rounded),
                        label: Text(_finishing
                            ? 'Saving…'
                            : _isLastExercise
                                ? 'Finish Workout'
                                : 'Next Exercise'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('This workout has no exercises yet.\n'
                          'Add exercises from your program.')),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _ProgressHeader(
                        done: _doneCount,
                        total: _exercises.length,
                        theme: theme),
                    const SizedBox(height: 16),
                    _ExerciseCard(
                      dayId: widget.workoutDayId,
                      index: _index,
                      total: _exercises.length,
                      exercise: _exercises[_index],
                      sets: _sets[_exercises[_index].id] ?? const [],
                      onAddSet: (weight, reps) =>
                          _addSet(_exercises[_index], weight: weight, reps: reps),
                      onUpdateSet: (s) => _updateSet(_exercises[_index], s),
                      onDeleteSet: (id) => _deleteSet(_exercises[_index], id),
                      onCompleteNext: () {
                        final completed = _completeNextSet(_exercises[_index]);
                        if (completed == null) {
                          _snack('Set a weight first');
                        } else {
                          _startRest();
                        }
                      },
                      onRest: _startRest,
                    ),
                  ],
                ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int done;
  final int total;
  final ThemeData theme;

  const _ProgressHeader({
    required this.done,
    required this.total,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Progress',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('$done / $total Exercises',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final String dayId;
  final int index;
  final int total;
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final void Function(double weight, int reps) onAddSet;
  final ValueChanged<WorkoutSet> onUpdateSet;
  final ValueChanged<String> onDeleteSet;
  final VoidCallback onCompleteNext;
  final VoidCallback onRest;

  const _ExerciseCard({
    required this.dayId,
    required this.index,
    required this.total,
    required this.exercise,
    required this.sets,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.onDeleteSet,
    required this.onCompleteNext,
    required this.onRest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final previous = ref.watch(lastPerformanceProvider(exercise.id));
    final configs = ref.watch(dayExerciseConfigsProvider(dayId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Exercise ${index + 1} / $total',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(exercise.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(exercise.primaryMuscle,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${exercise.equipment} • ${exercise.difficulty}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                previous.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (performance) {
                    if (performance == null) {
                      return Text('First time — no previous performance.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic));
                    }
                    final best = bestSet(performance.sets);
                    final completionStatus = _completionStatus(performance);
                    final suggestion =
                        _suggestion(ref, performance.sets, configs);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PreviousWorkoutBox(
                          performance: performance,
                          best: best,
                          theme: theme,
                        ),
                        if (_buildSuggestionCard(suggestion, theme) case
                            final card)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: card,
                          ),
                        if (completionStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _ProgressionStatusBanner(
                              status: completionStatus.$1,
                              previous: completionStatus.$2,
                              current: completionStatus.$3,
                              theme: theme,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (sets.isEmpty)
                  Text('No sets yet. Add a set to start logging.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic)),
                for (var i = 0; i < sets.length; i++)
                  _SetRow(
                    index: i + 1,
                    set: sets[i],
                    onChanged: onUpdateSet,
                    onDelete: () => onDeleteSet(sets[i].id),
                    onRest: onRest,
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onAddSet(0, 10),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Set'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onCompleteNext,
                        icon: Icon(Icons.check_circle_rounded,
                            size: 18, color: theme.colorScheme.primary),
                        label: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Suggestion from actual recorded data + the configured rep range, or null
  /// when there is no config to evaluate against.
  ProgressionSuggestion? _suggestion(
    WidgetRef ref,
    List<WorkoutSet> previousSets,
    AsyncValue<List<ProgramDayExercise>> configs,
  ) {
    final configsList = configs.valueOrNull ?? const <ProgramDayExercise>[];
    ProgramDayExercise? config;
    for (final c in configsList) {
      if (c.exerciseId == exercise.id) {
        config = c;
        break;
      }
    }
    return suggest(
      previousSets: previousSets,
      targetSets: config?.targetSets,
      minReps: config?.minReps,
      maxReps: config?.maxReps,
    );
  }

  /// The suggestion card (or nothing for empty/no-data outcomes). Hidden as
  /// soon as the user starts logging sets for this exercise.
  Widget? _buildSuggestionCard(
      ProgressionSuggestion? suggestion, ThemeData theme) {
    if (sets.isNotEmpty) return null;
    if (suggestion == null) return null;
    final outcome = suggestion.outcome;
    if (outcome == ProgressionOutcome.noPreviousData) return null;
    if (outcome == ProgressionOutcome.insufficientData) return null;
    if (outcome == ProgressionOutcome.noTargetRange) {
      return _SuggestionBox(
        icon: Icons.tune_rounded,
        message: suggestion.message,
        theme: theme,
      );
    }

    final suggested = suggestion.suggestedWeight;
    final previousW = suggestion.previousWeight;
    if (suggested == null || previousW == null) return null;

    final isIncrease = suggested != previousW;
    return _SuggestionBox(
      icon: Icons.trending_up_rounded,
      title: 'Suggested Progression',
      message: suggestion.message,
      reason: suggestion.reason,
      theme: theme,
      actions: isIncrease
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        onAddSet(previousW, suggestion.maxReps ?? 10),
                    child: const Text('Keep Previous Weight'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        onAddSet(suggested, suggestion.maxReps ?? 10),
                    child: Text('Use ${_weightNum(suggested)} kg'),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => onAddSet(suggested, suggestion.maxReps ?? 10),
                child: Text('Use ${_weightNum(suggested)} kg'),
              ),
            ),
    );
  }

  /// Inline status comparing the previous session to the current one, shown
  /// once every set of the current exercise is completed.
  (ProgressionStatus, WorkoutSet?, WorkoutSet?)? _completionStatus(
      ({DateTime date, List<WorkoutSet> sets}) performance) {
    if (sets.isEmpty || !sets.every((s) => s.completed)) return null;
    final current = bestSet(sets);
    final previousS = bestSet(performance.sets);
    if (current == null || previousS == null) return null;
    return (
      statusBetween(
        previousWeight: previousS.weight,
        previousReps: previousS.reps,
        currentWeight: current.weight,
        currentReps: current.reps,
      ),
      previousS,
      current,
    );
  }
}

String _weightNum(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class _PreviousWorkoutBox extends StatelessWidget {
  final ({DateTime date, List<WorkoutSet> sets}) performance;
  final WorkoutSet? best;
  final ThemeData theme;

  const _PreviousWorkoutBox({
    required this.performance,
    required this.best,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final volume = performance.sets
        .where((s) => s.completed && s.weight > 0)
        .fold<double>(0, (acc, s) => acc + s.weight * s.reps);
    final count = performance.sets.where((s) => s.completed).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Previous Workout',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(performance.date.displayMonthDay,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          for (final set in performance.sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${Formatters.weightKg(set.weight)} × ${set.reps}'
                '${set.rpe != null ? '  ·  RPE ${set.rpe}' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600),
              ),
            ),
          if (best != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$count sets • Best '
                '${Formatters.weightKg(best!.weight)} × ${best!.reps} '
                '• Volume ${Formatters.volumeKg(volume)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionBox extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? reason;
  final String? title;
  final ThemeData theme;
  final Widget? actions;

  const _SuggestionBox({
    required this.icon,
    required this.message,
    required this.theme,
    this.reason,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(title!,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          if (title == null)
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(message,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(reason!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ),
          if (actions != null) ...[
            const SizedBox(height: 10),
            actions!,
          ],
          const SizedBox(height: 4),
          Text('Optional suggestion — you stay in control. Always check your '
              'form before adding weight.',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ProgressionStatusBanner extends StatelessWidget {
  final ProgressionStatus status;
  final WorkoutSet? previous;
  final WorkoutSet? current;
  final ThemeData theme;

  const _ProgressionStatusBanner({
    required this.status,
    required this.theme,
    this.previous,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = status == ProgressionStatus.improved ||
        status == ProgressionStatus.repsImproved ||
        status == ProgressionStatus.maintained;
    final color = status == ProgressionStatus.improved
        ? AppColors.success
        : status == ProgressionStatus.noImprovement
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.success : theme.colorScheme.onSurfaceVariant)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(progressionStatusLabel(status),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          if (previous != null && current != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Current: ${_weightNum(current!.weight)} kg × ${current!.reps}'
                '   Previous: ${_weightNum(previous!.weight)} kg × '
                '${previous!.reps}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int index;
  final WorkoutSet set;
  final ValueChanged<WorkoutSet> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onRest;

  const _SetRow({
    required this.index,
    required this.set,
    required this.onChanged,
    required this.onDelete,
    required this.onRest,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _rpe;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
        text: widget.set.weight == 0 ? '' : _num(widget.set.weight));
    _reps = TextEditingController(text: _num(widget.set.reps));
    _rpe = TextEditingController(text: widget.set.rpe?.toString() ?? '');
  }

  String _num(num value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _rpe.dispose();
    super.dispose();
  }

  WorkoutSet _buildSet({bool? completed}) {
    final rpeText = _rpe.text.trim();
    var rpe = int.tryParse(rpeText);
    if (rpe != null && (rpe < 1 || rpe > 10)) rpe = null;
    return widget.set.copyWith(
      weight: double.tryParse(_weight.text.trim()) ?? 0,
      reps: int.tryParse(_reps.text.trim()) ?? 0,
      rpe: rpeText.isEmpty ? null : rpe,
      completed: completed ?? widget.set.completed,
    );
  }

  bool get _rpeInvalid {
    final text = _rpe.text.trim();
    if (text.isEmpty) return false;
    final value = int.tryParse(text);
    return value == null || value < 1 || value > 10;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = widget.set.completed;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: done
            ? AppColors.successSoft
            : theme.colorScheme.surfaceContainerHighest,
        border: done
            ? Border.all(color: AppColors.successOutline)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${widget.index}.',
                style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        done ? AppColors.success : theme.colorScheme.onSurface)),
          ),
          _field(_weight, 'kg', width: 54,
              onChanged: () => widget.onChanged(_buildSet())),
          const SizedBox(width: 6),
          Text('×',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 6),
          _field(_reps, 'reps', width: 54,
              onChanged: () => widget.onChanged(_buildSet())),
          const SizedBox(width: 6),
          _field(_rpe, 'RPE', width: 38,
              onChanged: () => widget.onChanged(_buildSet()),
              error: _rpeInvalid),
          IconButton(
            onPressed: widget.onRest,
            icon: const Icon(Icons.timer_outlined, size: 20),
            visualDensity: VisualDensity.compact,
            color: theme.colorScheme.primary,
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Checkbox(
            value: done,
            activeColor: AppColors.success,
            onChanged: (v) =>
                widget.onChanged(_buildSet(completed: v ?? false)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {required double width,
      required VoidCallback onChanged,
      bool error = false}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 9),
          errorText: error ? '1-10' : null,
          errorStyle: const TextStyle(fontSize: 8, height: 0.8),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}