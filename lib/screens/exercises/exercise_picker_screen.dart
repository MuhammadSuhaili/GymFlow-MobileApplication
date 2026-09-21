import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/providers/program_providers.dart';

/// Multi-select picker used to add exercises to a workout day.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  final List<String> alreadyAdded;
  final Future<void> Function(List<Exercise> selected) onConfirm;

  const ExercisePickerScreen({
    super.key,
    required this.alreadyAdded,
    required this.onConfirm,
  });

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final Set<String> _selected = {};
  String? _muscle;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.alreadyAdded);
  }

  Future<void> _confirm() async {
    final list = await ref.read(exercisesProvider(_muscle).future);
    final chosen = list
        .where((e) => _selected.contains(e.id))
        .toList();
    await widget.onConfirm(chosen);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercises = ref.watch(exercisesProvider(_muscle));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercises'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _confirm,
            child: Text('Add (${_selected.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _muscle == null,
                    onSelected: (_) => setState(() => _muscle = null),
                  ),
                ),
                ...['Chest', 'Back', 'Shoulder', 'Biceps', 'Triceps', 'Legs', 'Glutes', 'Core', 'Cardio']
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(m),
                            selected: _muscle == m,
                            onSelected: (_) => setState(() => _muscle = m),
                          ),
                        )),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load: $e'),
              data: (list) {
                final filtered = _query.trim().isEmpty
                    ? list
                    : list
                        .where((e) =>
                            e.name.toLowerCase().contains(_query.toLowerCase()))
                        .toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final isSelected = _selected.contains(item.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(item.id);
                          } else {
                            _selected.remove(item.id);
                          }
                        });
                      },
                      title: Text(item.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  isSelected ? null : null)),
                      subtitle: Text(
                          '${item.primaryMuscle} • ${item.equipment}'),
                      secondary: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}