import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/body_measurement.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/widgets/app_card.dart';
import 'package:gym_flow/widgets/empty_state.dart';
import 'package:gym_flow/widgets/line_chart.dart';
import 'package:uuid/uuid.dart';

/// Compact card embedded on the Progress tab.
class MeasurementsCard extends ConsumerWidget {
  const MeasurementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestMeasurementProvider);
    return AppCard(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MeasurementsScreen())),
      child: latest.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('No data'),
        data: (m) => Row(
          children: [
            const Icon(Icons.straighten_rounded, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest: ${m?.date.displayMonthDay ?? '—'}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    m == null
                        ? 'No measurements recorded yet.'
                        : '${m.weightKg != null ? Formatters.weightKg(m.weightKg) : '--'}'
                            '${m.bodyFat != null ? ' • ${m.bodyFat}% BF' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// Full body-measurements screen: weight chart, history + add/edit form.
class MeasurementsScreen extends ConsumerWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final measurements = ref.watch(measurementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Body Measurements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Measure'),
      ),
      body: measurements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.straighten_rounded,
              title: 'No measurements yet',
              message:
                  'Track weight, body fat and body circumferences over time.',
              actionLabel: 'Add Measurement',
            );
          }
          final withWeight =
              list.where((m) => m.weightKg != null).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              if (withWeight.length >= 2) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weight over time',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: LineChartView(
                            spots: withWeight
                                .map((m) => FlSpot(
                                    m.date.millisecondsSinceEpoch.toDouble() /
                                        86400000,
                                    m.weightKg!))
                                .toList(),
                            color: theme.colorScheme.tertiary,
                            xFormatter: (v) => DateTime
                                    .fromMillisecondsSinceEpoch(
                                        (v * 86400000).round())
                                .weekdayShort,
                            yFormatter: (v) => v.round().toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (withWeight.length == 1) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: const Text('Latest weight'),
                    subtitle: Text(Formatters.weightKg(withWeight.first.weightKg)),
                    trailing: Text(withWeight.first.date.displayMonthDay,
                        style: theme.textTheme.labelMedium),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ...list.reversed.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MeasurementTile(
                      item: m,
                      previous: _previousBefore(list, m),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  BodyMeasurement? _previousBefore(List<BodyMeasurement> list, BodyMeasurement current) {
    for (final m in list) {
      if (m.date.isBefore(current.date)) return m;
    }
    return null;
  }

  void _showForm(BuildContext context, WidgetRef ref, {BodyMeasurement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _MeasurementForm(existing: existing),
    );
  }
}

class _MeasurementForm extends ConsumerStatefulWidget {
  final BodyMeasurement? existing;
  const _MeasurementForm({this.existing});

  @override
  ConsumerState<_MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<_MeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _arm;
  late final TextEditingController _thigh;
  late final TextEditingController _hips;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    String text(double? v) => v == null ? '' : '${_trimZeros(v)}';
    _weight = TextEditingController(text: text(e?.weightKg));
    _bodyFat = TextEditingController(text: text(e?.bodyFat));
    _chest = TextEditingController(text: text(e?.chestCm));
    _waist = TextEditingController(text: text(e?.waistCm));
    _arm = TextEditingController(text: text(e?.armCm));
    _thigh = TextEditingController(text: text(e?.thighCm));
    _hips = TextEditingController(text: text(e?.hipsCm));
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  String _trimZeros(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _chest.dispose();
    _waist.dispose();
    _arm.dispose();
    _thigh.dispose();
    _hips.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = (String text) =>
        text.trim().isEmpty ? null : double.tryParse(text.trim());
    final existing = widget.existing;
    final m = BodyMeasurement(
      id: existing?.id ?? const Uuid().v4(),
      date: _date.dateOnly,
      weightKg: value(_weight.text),
      bodyFat: value(_bodyFat.text),
      chestCm: value(_chest.text),
      waistCm: value(_waist.text),
      armCm: value(_arm.text),
      thighCm: value(_thigh.text),
      hipsCm: value(_hips.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: existing?.createdAt,
    );
    await ref.read(measurementRepositoryProvider).save(m);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete measurement?'),
        content: Text(
            'Remove the entry for ${existing.date.displayMonthDay}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(measurementRepositoryProvider).delete(existing.id);
      ref.read(refreshTriggerProvider.notifier).bump();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                        widget.existing == null
                            ? 'Add Measurement'
                            : 'Edit Measurement',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text(_date.displayMonthDay),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field(_weight, 'Weight (kg)', required: true),
              const SizedBox(height: 10),
              _field(_bodyFat, 'Body Fat (%)'),
              const SizedBox(height: 10),
              _field(_chest, 'Chest (cm)'),
              const SizedBox(height: 10),
              _field(_waist, 'Waist (cm)'),
              const SizedBox(height: 10),
              _field(_hips, 'Hips (cm)'),
              const SizedBox(height: 10),
              _field(_arm, 'Arm (cm)'),
              const SizedBox(height: 10),
              _field(_thigh, 'Thigh (cm)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.existing == null
                    ? 'Save Measurement'
                    : 'Save Changes'),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _delete,
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Measurement'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return 'Weight is required';
        }
        if (v == null || v.trim().isEmpty) return null;
        final n = double.tryParse(v.trim());
        if (n == null) return 'Invalid number';
        if (n < 0) return 'Cannot be negative';
        return null;
      },
    );
  }
}

class _MeasurementTile extends ConsumerWidget {
  final BodyMeasurement item;
  final BodyMeasurement? previous;

  const _MeasurementTile({required this.item, this.previous});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => _MeasurementForm(existing: item),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.date.displayFull,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Icon(Icons.edit_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: _chips(context),
              ),
              if (item.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(item.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _chips(BuildContext context) {
    final theme = Theme.of(context);
    return [
      _valueChip(theme, 'Weight', item.weightKg, previous?.weightKg,
          (v) => Formatters.weightKg(v)),
      _valueChip(theme, 'BF', item.bodyFat, previous?.bodyFat,
          (v) => '${v}%'),
      _valueChip(theme, 'Chest', item.chestCm, previous?.chestCm,
          (v) => '${v}cm'),
      _valueChip(theme, 'Waist', item.waistCm, previous?.waistCm,
          (v) => '${v}cm'),
      _valueChip(theme, 'Hips', item.hipsCm, previous?.hipsCm,
          (v) => '${v}cm'),
      _valueChip(theme, 'Arm', item.armCm, previous?.armCm,
          (v) => '${v}cm'),
      _valueChip(theme, 'Thigh', item.thighCm, previous?.thighCm,
          (v) => '${v}cm'),
    ];
  }

  Widget _valueChip(ThemeData theme, String label, double? current,
      double? prev, String Function(double) fmt) {
    if (current == null) return const SizedBox.shrink();
    final diff = prev == null ? null : current - prev;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: fmt(current),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (diff != null && diff != 0)
              TextSpan(
                text:
                    ' ${diff > 0 ? '+' : ''}${fmt(diff.abs()).replaceAll(' kg', '')}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: diff > 0 ? AppColors.gold : AppColors.success,
                    fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}