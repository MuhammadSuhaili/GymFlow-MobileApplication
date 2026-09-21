import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/progress_models.dart';
import 'package:gym_flow/providers/monthly_report_providers.dart';
import 'package:gym_flow/services/monthly_report_service.dart';
import 'package:gym_flow/widgets/empty_state.dart';
import 'package:gym_flow/widgets/section_card.dart';
import 'package:gym_flow/widgets/stat_card.dart';

/// Monthly report: overview, month-over-month comparison, consistency, weekly
/// volume & frequency charts, strength progress, RPE and body measurements.
class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;

  bool get _canGoNext {
    final now = DateTime.now();
    if (_year != now.year) return _year < now.year;
    return _month < now.month;
  }

  void _prev() {
    setState(() {
      _month--;
      if (_month == 0) {
        _month = 12;
        _year--;
      }
    });
  }

  void _next() {
    if (!_canGoNext) return;
    setState(() {
      _month++;
      if (_month == 13) {
        _month = 1;
        _year++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = '${DateTime(_year, _month).monthLabel} $_year';
    final report = ref.watch(monthlyReportProvider((year: _year, month: _month)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: _prev,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous month',
              ),
              Text(label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: _canGoNext ? _next : null,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load report: $e')),
        data: (r) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (r.isEmpty)
              const SizedBox(
                height: 220,
                child: EmptyState(
                  icon: Icons.description_rounded,
                  title: 'No workouts in this month',
                  message:
                      'Complete a workout in this month to see your report here.',
                ),
              ),
            if (r.isEmpty) const SizedBox(height: 8),
            _OverviewSection(report: r, monthLabel: label),
            const SizedBox(height: 20),
            _ComparisonSection(r: r),
            const SizedBox(height: 20),
            _ConsistencySection(r: r, monthLabel: label),
            const SizedBox(height: 20),
            const _SectionTitle('Training Volume'),
            const SizedBox(height: 4),
            const Text('Total volume per calendar week.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            _WeeklyChartSection(buckets: r.volumeBuckets, volumeMode: true),
            const SizedBox(height: 20),
            const _SectionTitle('Workout Frequency'),
            const SizedBox(height: 4),
            const Text('Workouts completed per calendar week.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            _WeeklyChartSection(buckets: r.frequencyBuckets, volumeMode: false),
            const SizedBox(height: 20),
            const _SectionTitle('Strength Progress'),
            const SizedBox(height: 8),
            _StrengthSection(exercises: r.exercises),
            const SizedBox(height: 20),
            const _SectionTitle('Progression Highlights'),
            const SizedBox(height: 8),
            _HighlightsSection(exercises: r.exercises),
            const SizedBox(height: 20),
            const _SectionTitle('RPE Summary'),
            const SizedBox(height: 8),
            _RpeSection(r: r),
            const SizedBox(height: 20),
            const _SectionTitle('Program Summary'),
            const SizedBox(height: 8),
            _ProgramSection(r: r, monthLabel: label),
            const SizedBox(height: 20),
            const _SectionTitle('Body Weight'),
            const SizedBox(height: 8),
            _WeightSection(r: r),
            const SizedBox(height: 8),
            _MeasurementSection(r: r),
            if (r.measurements?.notes != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Measurement Notes',
                child: Text(r.measurements!.notes!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800));
  }
}

// ---------------------------------------------------------------- Overview

class _OverviewSection extends StatelessWidget {
  final MonthlyReport report;
  final String monthLabel;
  const _OverviewSection({required this.report, required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(monthLabel,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        _row([
          StatCard(
            icon: Icons.monitor_weight_outlined,
            value: Formatters.weightKg(report.latestWeightKg),
            label: 'Latest Weight',
          ),
          StatCard(
            icon: Icons.fitness_center_rounded,
            value: '${report.workouts}',
            label: 'Workouts',
          ),
        ]),
        const SizedBox(height: 10),
        _row([
          StatCard(
            icon: Icons.straighten_rounded,
            value: Formatters.volumeKg(report.volume),
            label: 'Total Volume',
          ),
          StatCard(
            icon: Icons.timer_outlined,
            value: Formatters.duration(report.totalDurationMinutes),
            label: 'Total Duration',
          ),
        ]),
        const SizedBox(height: 10),
        _row([
          StatCard(
            icon: Icons.schedule_rounded,
            value: Formatters.duration(report.avgDurationMinutes),
            label: 'Avg Workout',
          ),
          StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${report.longestStreakInMonth}',
            label: 'Longest Streak (month)',
            iconColor: Theme.of(context).colorScheme.primary,
          ),
        ]),
        const SizedBox(height: 10),
        _row([
          StatCard(
            icon: Icons.whatshot_rounded,
            value: '${report.currentStreakDays}',
            label: 'Current Streak',
            iconColor: Theme.of(context).colorScheme.primary,
          ),
          StatCard(
            icon: Icons.emoji_events_rounded,
            value: '${report.bestStreakDays}',
            label: 'Best Streak',
          ),
        ]),
      ],
    );
  }

  Widget _row(List<StatCard> tiles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tiles[0]),
        const SizedBox(width: 10),
        Expanded(child: tiles[1]),
      ],
    );
  }
}

// -------------------------------------------------------------- Comparison

class _ComparisonSection extends StatelessWidget {
  final MonthlyReport r;
  const _ComparisonSection({required this.r});

  @override
  Widget build(BuildContext context) {
    return _SectionCard('Month over Month', 'Compared with the previous month',
        child: !r.hasPreviousMonthData
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No previous-month data.'),
              )
            : Column(
                children: [
                  _compRow(context, 'Workouts',
                      '${r.workouts}', '${r.previousWorkouts}',
                      r.workoutsDeltaPercent),
                  const Divider(height: 16),
                  _compRow(context, 'Total Volume',
                      Formatters.volumeKg(r.volume),
                      Formatters.volumeKg(r.previousVolume),
                      r.volumeDeltaPercent),
                  const Divider(height: 16),
                  _compRow(context, 'Total Sets',
                      '${r.completedSets}', '${r.previousCompletedSets}',
                      r.completedSetsDeltaPercent),
                  const Divider(height: 16),
                  _compRow(context, 'Total Reps',
                      '${r.totalReps}', '${r.previousTotalReps}',
                      r.totalRepsDeltaPercent),
                  const Divider(height: 16),
                  _compRow(context, 'Avg Duration',
                      Formatters.duration(r.avgDurationMinutes),
                      Formatters.duration(r.previousAvgDurationMinutes),
                      r.avgDurationDeltaPercent),
                ],
              ));
  }

  Widget _compRow(
    BuildContext context,
    String label,
    String current,
    String previous,
    double? delta,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(current,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text('Previous: $previous',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _DeltaText(delta: delta),
      ],
    );
  }
}

class _DeltaText extends StatelessWidget {
  final double? delta;
  const _DeltaText({required this.delta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (delta == null) {
      return const Text('--',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12));
    }
    final d = delta!;
    final up = d >= 0;
    final color = up ? AppColors.success : theme.colorScheme.error;
    final rounded = d.abs().toStringAsFixed(0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${up ? '+' : '-'}$rounded%',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Consistency

class _ConsistencySection extends StatelessWidget {
  final MonthlyReport r;
  final String monthLabel;
  const _ConsistencySection({required this.r, required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!r.consistencyAvailable) {
      return _SectionCard('Consistency', 'Planned vs completed workouts',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Consistency can\u2019t be determined for $monthLabel — no active '
              'program covered this month with a reliably reconstructible '
              'schedule.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ));
    }
    final percent = (r.consistencyPercent ?? 0);
    return _SectionCard('Consistency',
        '${r.consistencyCompleted} of ${r.consistencyScheduled} planned workouts',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text('${(percent * 100).toStringAsFixed(1)}% of the planned '
                'workout days completed.',
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary)),
          ],
        ));
  }
}

// ----------------------------------------------------------------- Charts

class _WeeklyChartSection extends StatelessWidget {
  final List<ProgressBucket> buckets;
  final bool volumeMode;
  const _WeeklyChartSection({required this.buckets, required this.volumeMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      volumeMode ? 'Volume per week' : 'Frequency per week',
      volumeMode
          ? 'Total volume (kg) for each calendar week.'
          : 'Completed workouts for each calendar week.',
      child: buckets.isEmpty
          ? const SizedBox(
              height: 140,
              child: EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'No data',
                message: 'Complete a workout to see this chart.',
              ),
            )
          : SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: volumeMode
                      ? (buckets
                                  .map((b) => b.volume)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.15)
                          .clamp(1.0, double.infinity)
                      : (buckets
                                  .map((b) => b.workouts.toDouble())
                                  .reduce((a, b) => a > b ? a : b) *
                              1.15)
                          .clamp(1.0, double.infinity),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bucket = buckets[groupIndex];
                        return BarTooltipItem(
                          '${bucket.start.displayMonthDay}\n'
                          '${volumeMode ? Formatters.volumeKg(bucket.volume) : '${bucket.workouts} workout${bucket.workouts == 1 ? '' : 's'}'}',
                          theme.textTheme.labelSmall!.copyWith(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: volumeMode
                        ? AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true, reservedSize: 40))
                        : const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: (buckets.length / 6).ceil().toDouble(),
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i % (buckets.length / 6).ceil() != 0 ||
                              i < 0 ||
                              i >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(buckets[i].label,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: volumeMode
                                ? buckets[i].volume
                                : buckets[i].workouts.toDouble(),
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                            color: volumeMode
                                ? theme.colorScheme.primary.withValues(alpha: 0.85)
                                : theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------- Strength

class _StrengthSection extends StatelessWidget {
  final List<ExerciseMonthBest> exercises;
  const _StrengthSection({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return _SectionCard('Best lift per exercise',
        'Highest weight reached this month vs the previous best.',
        child: exercises.isEmpty
            ? const SizedBox(
                height: 120,
                child: EmptyState(
                  icon: Icons.show_chart_rounded,
                  title: 'No exercises yet',
                  message: 'Add lifts this month and they will compare here.',
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < exercises.length; i++) ...[
                    _exerciseRow(exercises[i]),
                    if (i != exercises.length - 1) const Divider(height: 16),
                  ],
                ],
              ));
  }

  Widget _exerciseRow(ExerciseMonthBest e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(e.previousBestWeight == null
                  ? 'First time lifting this month.'
                  : 'Previous best: ${_lift(e.previousBestWeight!, e.previousBestReps!)}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_lift(e.monthBestWeight, e.monthBestReps),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${e.monthSessions} session${e.monthSessions == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  String _lift(double weight, int reps) =>
      '${Formatters.weightNum(weight)} kg × $reps';
}

// --------------------------------------------------------------- Highlights

class _HighlightsSection extends StatelessWidget {
  final List<ExerciseMonthBest> exercises;
  const _HighlightsSection({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = exercises.take(3).toList();
    return _SectionCard('Top exercises this month',
        'Ranked by improvement against their previous best.',
        child: top.isEmpty
            ? const SizedBox(
                height: 100,
                child: EmptyState(
                  icon: Icons.trending_up_rounded,
                  title: 'Nothing to highlight yet',
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(top[i].exerciseName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(top[i].status.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    if (i != top.length - 1) const Divider(height: 16),
                  ],
                ],
              ));
  }
}

// --------------------------------------------------------------------- RPE

class _RpeSection extends StatelessWidget {
  final MonthlyReport r;
  const _RpeSection({required this.r});

  @override
  Widget build(BuildContext context) {
    return _SectionCard('Average RPE', 'Intensity across completed sets.',
        child: r.avgRpe == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('RPE data is limited for this month.'),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${r.avgRpe!.toStringAsFixed(1)} / 10',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Text('from ${r.rpeSetCount} rated sets',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ));
  }
}

// ----------------------------------------------------------------- Program

class _ProgramSection extends StatelessWidget {
  final MonthlyReport r;
  final String monthLabel;
  const _ProgramSection({required this.r, required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = r.program;
    if (p == null) {
      return _SectionCard('Active program', 'Program coverage for this month.',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No active program covered $monthLabel.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ));
    }
    final ratio = p.scheduledWorkouts == 0
        ? 0.0
        : (p.completedWorkouts / p.scheduledWorkouts).clamp(0.0, 1.0);
    return _SectionCard(p.name, '${p.goal} • ${p.durationWeeks} weeks',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text('${p.completedWorkouts} of ${p.scheduledWorkouts} planned '
                'workouts completed.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ));
  }
}

// ----------------------------------------------------------- Body & measure

class _WeightSection extends StatelessWidget {
  final MonthlyReport r;
  const _WeightSection({required this.r});

  @override
  Widget build(BuildContext context) {
    final m = r.measurements;
    final start = m?.startWeightKg;
    final end = m?.endWeightKg;
    if (start == null && end == null) {
      return const _SectionCard('Body weight', 'Starting vs ending weight.',
          child: SizedBox(
            height: 80,
            child: EmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'No weight records',
              message: 'Add a body measurement this month to see it here.',
            ),
          ));
    }
    final delta = (start == null || end == null) ? null : end - start;
    return _SectionCard('Body weight', 'Starting vs ending weight.',
        child: Row(
          children: [
            _weightTile(context, start, 'Start'),
            const Expanded(child: Icon(Icons.arrow_forward_rounded, size: 18)),
            _weightTile(context, end, 'End'),
            const SizedBox(width: 14),
            Text(
              delta == null
                  ? '--'
                  : '${delta >= 0 ? '+' : ''}${Formatters.weightNum(delta)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: delta == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : delta >= 0
                          ? AppColors.success
                          : Theme.of(context).colorScheme.error),
            ),
          ],
        ));
  }

  Widget _weightTile(BuildContext context, double? value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Formatters.weightKg(value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MeasurementSection extends StatelessWidget {
  final MonthlyReport r;
  const _MeasurementSection({required this.r});

  @override
  Widget build(BuildContext context) {
    final m = r.measurements;
    if (m == null) return const SizedBox.shrink();
    return _SectionCard('Measurement changes',
        '${m.firstDate.displayShort} → ${m.lastDate.displayShort}',
        child: Column(
          children: [
            _measRow(context, 'Body fat (%)', m.bodyFatStart, m.bodyFatEnd, m.bodyFatDelta),
            _measRow(context, 'Chest (cm)', m.chestStart, m.chestEnd, m.chestDelta),
            _measRow(context, 'Waist (cm)', m.waistStart, m.waistEnd, m.waistDelta),
            _measRow(context, 'Arm (cm)', m.armStart, m.armEnd, m.armDelta),
            _measRow(context, 'Thigh (cm)', m.thighStart, m.thighEnd, m.thighDelta),
            _measRow(context, 'Hips (cm)', m.hipsStart, m.hipsEnd, m.hipsDelta),
          ],
        ));
  }

  Widget _measRow(
    BuildContext context,
    String label,
    double? start,
    double? end,
    double? delta,
  ) {
    if (start == null && end == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: Text(
              '${start == null ? '--' : Formatters.double1(start)} → '
              '${end == null ? '--' : Formatters.double1(end)}',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              delta == null
                  ? '--'
                  : '${delta >= 0 ? '+' : ''}${delta.abs().toStringAsFixed(1)}',
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: delta == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : delta >= 0
                          ? AppColors.success
                          : Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ helpers

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard(this.title, this.subtitle, {required this.child});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}