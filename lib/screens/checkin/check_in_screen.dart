import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/models/daily_check_in.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/providers/settings_providers.dart';
import 'package:gym_flow/widgets/mood_selector.dart';
import 'package:gym_flow/widgets/rating_selector.dart';
import 'package:gym_flow/widgets/section_card.dart';
import 'package:uuid/uuid.dart';

/// Daily check-in form. One per day, but the current day is editable.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sleepHours = TextEditingController(text: '7');
  final _sleepMinutes = TextEditingController(text: '0');
  final _weight = TextEditingController();
  final _notes = TextEditingController();

  int _mood = 3;
  int _energy = 3;
  int _sleepQuality = 3;
  int _soreness = 2;
  int _motivation = 4;
  bool _loaded = false;
  bool _saved = false;
  DailyCheckIn? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await ref
        .read(checkinRepositoryProvider)
        .getByDate(DateTime.now().dateOnly);
    if (!mounted) return;
    final unit = ref.read(unitSystemProvider);
    setState(() {
      _existing = existing;
      if (existing != null) {
        _mood = existing.mood;
        _energy = existing.energy;
        _sleepHours.text = existing.sleepHours.toString();
        _sleepMinutes.text = existing.sleepMinutes.toString();
        _sleepQuality = existing.sleepQuality;
        _soreness = existing.soreness;
        _motivation = existing.motivation;
        if (existing.weightKg != null) {
          _weight.text = _weightText(_kgToDisplay(unit, existing.weightKg!));
        }
        _notes.text = existing.notes ?? '';
      } else {
        final user = ref.read(userProvider).valueOrNull;
        if (user != null) {
          _weight.text = _weightText(_kgToDisplay(unit, user.weightKg));
        }
      }
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _sleepHours.dispose();
    _sleepMinutes.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawWeight = _weight.text.trim();
    final unit = ref.read(unitSystemProvider);
    final weight = rawWeight.isEmpty
        ? _existing?.weightKg
        : _displayToKg(unit, double.parse(rawWeight));
    final checkin = DailyCheckIn(
      id: _existing?.id ?? const Uuid().v4(),
      date: DateTime.now().dateOnly,
      mood: _mood,
      energy: _energy,
      sleepHours: int.parse(_sleepHours.text.trim()),
      sleepMinutes: int.parse(_sleepMinutes.text.trim()),
      sleepQuality: _sleepQuality,
      soreness: _soreness,
      motivation: _motivation,
      weightKg: weight,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    await ref.read(checkinRepositoryProvider).save(checkin);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : _saved
            ? _SavedView(onDone: () => Navigator.of(context).pop())
            : Column(
                children: [
                  Expanded(child: _form(context)),
                  _saveBar(context),
                ],
              ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(unitSystemProvider);
    final unitShort = _usesMetric(unit) ? 'kg' : 'lb';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling today?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateTime.now().displayFull,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '1 minute a day to track how your body responds '
              'to training.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Mood',
              subtitle: 'How you feel right now.',
              leading: Icons.sentiment_satisfied_alt_rounded,
              child: MoodSelector(
                value: _mood,
                onChanged: (v) => setState(() => _mood = v),
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Energy',
              subtitle: 'Your energy today.',
              leading: Icons.bolt_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RatingSelector(
                    value: _energy,
                    onChanged: (v) => setState(() => _energy = v),
                  ),
                  const SizedBox(height: 8),
                  RatingScaleLabel(
                    value: _energy,
                    labels: const [
                      'Drained',
                      'Low',
                      'Okay',
                      'Good',
                      'High',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Sleep',
              subtitle: 'Total sleep last night.',
              leading: Icons.bedtime_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sleepHours,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration:
                          const InputDecoration(labelText: 'Hours'),
                      validator: _sleepHoursValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sleepMinutes,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration:
                          const InputDecoration(labelText: 'Minutes'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 59) return '0-59';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Sleep Quality',
              subtitle: 'How well you slept.',
              leading: Icons.bed_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RatingSelector(
                    value: _sleepQuality,
                    onChanged: (v) => setState(() => _sleepQuality = v),
                  ),
                  const SizedBox(height: 8),
                  RatingScaleLabel(
                    value: _sleepQuality,
                    labels: const [
                      'Very poor',
                      'Poor',
                      'Okay',
                      'Good',
                      'Excellent',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Muscles',
              subtitle: 'Muscle soreness today.',
              leading: Icons.healing_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RatingSelector(
                    value: _soreness,
                    onChanged: (v) => setState(() => _soreness = v),
                  ),
                  const SizedBox(height: 8),
                  RatingScaleLabel(
                    value: _soreness,
                    labels: const [
                      'No soreness',
                      'Slight',
                      'Moderate',
                      'Sore',
                      'Very sore',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Motivation',
              subtitle: 'How ready you are to train.',
              leading: Icons.flag_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RatingSelector(
                    value: _motivation,
                    onChanged: (v) => setState(() => _motivation = v),
                  ),
                  const SizedBox(height: 8),
                  RatingScaleLabel(
                    value: _motivation,
                    labels: const [
                      'No drive',
                      'Low',
                      'Okay',
                      'Motivated',
                      'Ready to go',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Weight',
              subtitle: 'Optional — morning weight is most consistent.',
              leading: Icons.monitor_weight_rounded,
              child: TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Your weight',
                  suffixText: unitShort,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Enter a valid number';
                  if (n < 0) return 'Cannot be negative';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            SectionCard(
              title: 'Notes',
              subtitle: 'Optional.',
              leading: Icons.sticky_note_2_rounded,
              child: TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'E.g. Slightly tired, slept late last night.',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: Text(_existing != null ? 'Update Check-in' : 'Save Check-in'),
        ),
      ),
    );
  }

  static String? _sleepHoursValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0 || n > 24) return '0-24';
    return null;
  }

  static bool _usesMetric(String unit) => unit.startsWith('Metric');

  /// Converts a stored kg value into the display unit.
  static double _kgToDisplay(String unit, double kg) =>
      _usesMetric(unit) ? kg : kg * 2.20462;

  /// Converts a display-unit value back into stored kg.
  static double _displayToKg(String unit, double value) =>
      _usesMetric(unit) ? value : value / 2.20462;

  static String _weightText(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
}

class _SavedView extends StatelessWidget {
  final VoidCallback onDone;

  const _SavedView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successSoft,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Check-in completed ✓',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job showing up for yourself today.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onDone, child: const Text('Back to Home')),
          ],
        ),
      ),
    );
  }
}
