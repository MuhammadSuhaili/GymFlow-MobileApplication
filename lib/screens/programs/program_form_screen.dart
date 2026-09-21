import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/core/utils/validators.dart';
import 'package:gym_flow/models/program.dart';
import 'package:gym_flow/models/workout_template.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/programs/program_detail_screen.dart';

/// Create or edit a program.
class ProgramFormScreen extends ConsumerStatefulWidget {
  final Program? program;

  const ProgramFormScreen({super.key, this.program});

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _goal;
  int _durationWeeks = 12;
  String _templateId = WorkoutTemplate.pushPullLegs.id;

  bool get _isEdit => widget.program != null;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _name = TextEditingController(text: p?.name ?? '');
    _goal = p?.goal ?? GymGoals.muscleBuilding;
    _durationWeeks = p?.durationWeeks ?? 12;
    _templateId = p?.templateName ?? WorkoutTemplate.pushPullLegs.id;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(programRepositoryProvider);

    if (_isEdit) {
      final updated = widget.program!.copyWith(
        name: _name.text.trim(),
        goal: _goal,
      );
      await repo.updateProgram(updated);
      ref.read(refreshTriggerProvider.notifier).bump();
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final program = await repo.createProgram(
      name: _name.text.trim(),
      durationWeeks: _durationWeeks,
      goal: _goal,
      templateName: _templateId,
    );
    await repo.setActive(program.id);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Program' : 'New Program')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Program Name',
                  hintText: 'e.g. My Hypertrophy Program',
                  prefixIcon: Icon(Icons.fitness_center_rounded),
                ),
                validator: (v) => Validators.required(v, label: 'Program name'),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(
                  labelText: 'Goal',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: fitnessGoals
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _goal = v ?? _goal),
              ),
              const SizedBox(height: 16),

              _DurationCard(
                weeks: _durationWeeks,
                editable: !_isEdit,
                onChanged: (w) => setState(() => _durationWeeks = w),
              ),
              const SizedBox(height: 16),

              // Template selection — new programs only.
              if (_isEdit) ...[
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Template & duration locked for existing programs'),
                  subtitle: Text('You can still edit the weekly schedule directly.'),
                ),
              ] else
                _TemplatePicker(
                  selectedId: _templateId,
                  onSelected: (id) => setState(() => _templateId = id),
                ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(
                    _isEdit ? Icons.save_rounded : Icons.arrow_forward_rounded),
                label: Text(_isEdit
                    ? 'Save Changes'
                    : 'Create & Configure Program'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final int weeks;
  final bool editable;
  final ValueChanged<int> onChanged;

  const _DurationCard({
    required this.weeks,
    required this.editable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: (editable && weeks > 1)
                      ? () => onChanged(weeks - 1)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text('$weeks weeks',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: (editable && weeks < 52)
                      ? () => onChanged(weeks + 1)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            Align(
              child: Text('${(weeks / 4).ceil()} month(s)',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _TemplatePicker({
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start From Template',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Pick a starting schedule — you can tweak it before saving.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...WorkoutTemplate.creatable.map((template) {
              final selected = selectedId == template.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(template.id),
                  child: Ink(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.primary, width: 1.6)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(template.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  template.daysPerWeek == 0
                                      ? 'Build your own'
                                      : '${template.daysPerWeek} days/week',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}