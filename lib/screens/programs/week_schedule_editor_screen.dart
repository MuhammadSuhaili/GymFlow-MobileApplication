import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/models/workout_day.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/widgets/app_card.dart';

/// Full weekly schedule editor. Edits all 7 days of one week.
class WeekScheduleEditorScreen extends ConsumerStatefulWidget {
  final String programId;
  final String weekId;

  const WeekScheduleEditorScreen({
    super.key,
    required this.programId,
    required this.weekId,
  });

  @override
  ConsumerState<WeekScheduleEditorScreen> createState() =>
      _WeekScheduleEditorScreenState();
}

class _WeekScheduleEditorScreenState
    extends ConsumerState<WeekScheduleEditorScreen> {
  late List<WorkoutDay> _days;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = await ref
        .read(programRepositoryProvider)
        .getDaysForWeek(widget.weekId);
    if (!mounted) return;
    setState(() {
      _days = days;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(programRepositoryProvider)
        .updateWeekSchedule(widget.programId, widget.weekId, _days);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyToAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy to all weeks?'),
        content: const Text(
          'This schedule will replace the schedule of every week in the program.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(programRepositoryProvider)
        .copyWeekToAll(widget.programId, widget.weekId);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to all weeks'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateDay(int index, WorkoutDay day) {
    setState(() => _days[index] = day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Saving…' : 'Save Week'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          Text(
            'Tap a day to edit its workout (or mark it as rest).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ..._days.map((day) {
            final index = day.dayOfWeek - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EditableDayRow(
                day: day,
                onChanged: (updated) => _updateDay(index, updated),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _copyToAll,
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copy this week to all weeks'),
          ),
        ],
      ),
    );
  }
}

class _EditableDayRow extends StatefulWidget {
  final WorkoutDay day;
  final ValueChanged<WorkoutDay> onChanged;

  const _EditableDayRow({required this.day, required this.onChanged});

  @override
  State<_EditableDayRow> createState() => _EditableDayRowState();
}

class _EditableDayRowState extends State<_EditableDayRow> {
  late String _title = workoutTitles.contains(widget.day.title)
      ? widget.day.title
      : (widget.day.isRest ? workoutTitles.first : widget.day.title);
  late bool _isRest = widget.day.isRest;

  void _emit() {
    widget.onChanged(
      widget.day.copyWith(title: _isRest ? 'Rest' : _title, isRest: _isRest),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _isRest
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.day.dayOfWeek.weekdayShort,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _isRest
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _isRest ? 'Rest Day' : (widget.day.dayOfWeek.dayOfWeekFull),
              ),
              subtitle: _isRest
                  ? null
                  : DropdownButtonFormField<String>(
                      initialValue: _title,
                      isDense: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Workout title',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: workoutTitles
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _title = v ?? _title);
                        _emit();
                      },
                    ),
              value: !_isRest,
              onChanged: (v) {
                setState(() => _isRest = !v);
                _emit();
              },
            ),
          ),
        ],
      ),
    );
  }
}
