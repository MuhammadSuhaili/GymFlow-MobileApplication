import 'package:flutter/material.dart';
import 'package:gym_flow/core/utils/validators.dart';
import 'package:gym_flow/models/exercise.dart';

/// Configures the target sets, rep range, optional starting weight and notes
/// of an exercise inside a program day. Only the rep range is required to
/// enable progression suggestions — sets/weight/notes stay optional.
class ExerciseConfigDialog extends StatefulWidget {
  final String exerciseName;
  final ProgramDayExercise initial;

  const ExerciseConfigDialog({
    super.key,
    required this.exerciseName,
    required this.initial,
  });

  @override
  State<ExerciseConfigDialog> createState() => _ExerciseConfigDialogState();
}

class _ExerciseConfigDialogState extends State<ExerciseConfigDialog> {
  late final TextEditingController _sets;
  late final TextEditingController _minReps;
  late final TextEditingController _maxReps;
  late final TextEditingController _startingWeight;
  late final TextEditingController _notes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(text: widget.initial.targetSets?.toString() ?? '');
    _minReps = TextEditingController(text: widget.initial.minReps?.toString() ?? '');
    _maxReps = TextEditingController(text: widget.initial.maxReps?.toString() ?? '');
    _startingWeight =
        TextEditingController(text: widget.initial.startingWeight == null ? '' : _num(widget.initial.startingWeight!));
    _notes = TextEditingController(text: widget.initial.notes ?? '');
  }

  @override
  void dispose() {
    _sets.dispose();
    _minReps.dispose();
    _maxReps.dispose();
    _startingWeight.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _num(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  ProgramDayExercise? _build() {
    final setsText = _sets.text.trim();
    final minText = _minReps.text.trim();
    final maxText = _maxReps.text.trim();
    final weightText = _startingWeight.text.trim();

    final hasAnyRep = minText.isNotEmpty || maxText.isNotEmpty;
    if (hasAnyRep) {
      final min = int.tryParse(minText);
      final max = int.tryParse(maxText);
      final sets = setsText.isEmpty ? null : int.tryParse(setsText);
      if (min == null || max == null || min <= 0 || max < min) {
        _error = 'Enter a valid rep range (e.g. 8 – 10).';
        return null;
      }
      if (sets != null && sets <= 0) {
        _error = 'Target sets must be 1 or more.';
        return null;
      }
      if (weightText.isNotEmpty && Validators.positiveNumber(weightText) != null) {
        _error = 'Starting weight must be greater than 0.';
        return null;
      }
      return widget.initial.copyWith(
        targetSets: sets,
        minReps: min,
        maxReps: max,
        startingWeight: weightText.isEmpty ? null : double.parse(weightText),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    }

    // Rep range cleared → config removed entirely.
    return widget.initial.copyWith(
      targetSets: null,
      minReps: null,
      maxReps: null,
      startingWeight: weightText.isEmpty ? null : double.parse(weightText),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Configure ${widget.exerciseName}',
          style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target sets and the rep range drive the optional '
                'progression suggestion during your workout.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: _sets,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sets',
                hintText: '3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minReps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min reps',
                      hintText: '8',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxReps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max reps',
                      hintText: '10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startingWeight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Starting weight (kg) — optional',
                hintText: '40',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes — optional',
                hintText: 'Controlled eccentric',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final result = _build();
            if (result == null) {
              setState(() {});
              return;
            }
            Navigator.pop(context, result);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}