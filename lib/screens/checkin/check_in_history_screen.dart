import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/data/repositories/checkin_repository.dart';
import 'package:gym_flow/models/daily_check_in.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/widgets/empty_state.dart';

/// Check-in history with filters.
class CheckInHistoryScreen extends ConsumerStatefulWidget {
  const CheckInHistoryScreen({super.key});

  @override
  ConsumerState<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends ConsumerState<CheckInHistoryScreen> {
  CheckInFilter _filter = CheckInFilter.thisMonth;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (start != null) {
      setState(() => _filter = CheckInFilter.custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in History')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Today',
                  selected: _filter == CheckInFilter.today,
                  onTap: () => setState(() => _filter = CheckInFilter.today),
                ),
                _FilterChip(
                  label: 'This Week',
                  selected: _filter == CheckInFilter.thisWeek,
                  onTap: () => setState(() => _filter = CheckInFilter.thisWeek),
                ),
                _FilterChip(
                  label: 'This Month',
                  selected: _filter == CheckInFilter.thisMonth,
                  onTap: () =>
                      setState(() => _filter = CheckInFilter.thisMonth),
                ),
                _FilterChip(
                  label: 'All',
                  selected: _filter == CheckInFilter.all,
                  onTap: () => setState(() => _filter = CheckInFilter.all),
                ),
                _FilterChip(
                  label: 'Custom Date',
                  selected: _filter == CheckInFilter.custom,
                  onTap: _pickCustomRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filter == CheckInFilter.custom
                ? const _CustomRangeView()
                : CheckInListView(filter: _filter),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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

class CheckInListView extends ConsumerWidget {
  final CheckInFilter filter;

  const CheckInListView({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(checkinsFilteredProvider(filter));
    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Failed to load: $e'),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.event_note_outlined,
            title: 'No check-ins',
            message: 'Records from your daily check-ins will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _CheckInTile(item: list[i]),
        );
      },
    );
  }
}

class _CustomRangeView extends ConsumerStatefulWidget {
  const _CustomRangeView();

  @override
  ConsumerState<_CustomRangeView> createState() => _CustomRangeViewState();
}

class _CustomRangeViewState extends ConsumerState<_CustomRangeView> {
  DateTimeRange? _range;

  Future<void> _pick() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range,
    );
    if (range != null) setState(() => _range = range);
  }

  @override
  Widget build(BuildContext context) {
    if (_range == null) {
      return EmptyState(
        icon: Icons.date_range_outlined,
        title: 'Pick a date range',
        message: 'Choose custom dates to filter your check-ins.',
        actionLabel: 'Choose Dates',
        onAction: _pick,
      );
    }
    final items = ref.watch(checkinsCustomProvider(_range));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_range!.start.displayShort} – ${_range!.end.displayShort}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              TextButton(onPressed: _pick, child: const Text('Change')),
            ],
          ),
        ),
        Expanded(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed: $e'),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No check-ins',
                    message: 'Nothing recorded in this range yet.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CheckInTile(item: list[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CheckInTile extends StatelessWidget {
  final DailyCheckIn item;

  const _CheckInTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = Mood.fromValue(item.mood);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.date.displayMonthDay,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(mood?.emoji ?? '🙂', style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Info(label: 'Mood', value: mood?.label ?? '—'),
                _Info(label: 'Energy', value: '${item.energy}/5'),
                _Info(
                    label: 'Sleep',
                    value: Formatters.sleepDuration(
                        item.sleepHours, item.sleepMinutes)),
                _Info(label: 'Soreness', value: '${item.soreness}/5'),
                _Info(
                    label: 'Weight',
                    value: item.weightKg != null
                        ? Formatters.weightKg(item.weightKg)
                        : '—'),
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('"${item.notes}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;

  const _Info({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        Text(value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}