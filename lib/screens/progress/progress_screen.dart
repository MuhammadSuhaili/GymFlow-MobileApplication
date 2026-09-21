import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/progress_models.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/screens/calendar/calendar_screen.dart';
import 'package:gym_flow/screens/progress/exercise_progress_screen.dart';
import 'package:gym_flow/screens/progress/measurements_screen.dart';
import 'package:gym_flow/widgets/empty_state.dart';
import 'package:gym_flow/widgets/line_chart.dart';
import 'package:gym_flow/widgets/section_card.dart';
import 'package:gym_flow/widgets/stat_card.dart';

/// Progress dashboard: statistics, strength, frequency & volume over time.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  TimeRange _range = TimeRange.thirtyDays;
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overview = ref.watch(progressOverviewProvider(_range));

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<TimeRange>(
            segments: TimeRange.values
                .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                .toList(),
            selected: {_range},
            onSelectionChanged: (selection) =>
                setState(() => _range = selection.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          overview.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Failed to load: $e'),
            data: (data) {
              if (data.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: EmptyState(
                    icon: Icons.show_chart_rounded,
                    title: 'No workout data yet',
                    message:
                        'Finish a workout and your progress will show up here.',
                  ),
                );
              }
              return Column(
                children: [
                  _StatsGrid(data: data),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          _StatsStreakRangeBanner(range: _range),
          const SizedBox(height: 16),

          Text('Strength Progress',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StrengthProgressSection(
            range: _range,
            exerciseId: _selectedExerciseId,
            onExerciseChanged: (id) =>
                setState(() => _selectedExerciseId = id),
          ),
          const SizedBox(height: 20),

          Text('Workout Frequency',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Workouts completed per ${_range.isDaily ? 'day' : 'week'}.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          FrequencySection(range: _range),
          const SizedBox(height: 20),

          Text('Training Volume',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Total volume per ${_range.isDaily ? 'day' : 'week'}.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          VolumeSection(range: _range),
          const SizedBox(height: 20),

          Text('Body Weight',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const WeightProgressSection(),
          const SizedBox(height: 14),
          const MeasurementsCard(),
          const SizedBox(height: 14),
          AppCardLink(
            icon: Icons.calendar_month_rounded,
            title: 'Workout Calendar',
            subtitle: 'See scheduled, completed, missed and rest days',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CalendarScreen())),
          ),
        ],
      ),
    );
  }
}

class AppCardLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

const AppCardLink({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

/// Current streak chip shown under the stats grid.
class _StatsStreakRangeBanner extends ConsumerWidget {
  final TimeRange range;
  const _StatsStreakRangeBanner({required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streak = ref.watch(streakProvider);
    final label = range.isAllTime ? 'all time' : 'last ${range.days} days';
    return Row(
      children: [
        Text('Based on $label.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        streak.when(
          data: (s) => Row(
            children: [
Icon(Icons.local_fire_department_rounded,
                  color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 4),
              Text('${s.current}-day streak',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Stats

class _StatsGrid extends StatelessWidget {
  final ProgressOverview data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return _row(
      tiles: [
        _t('Workouts', '${data.workouts}', Icons.fitness_center_rounded),
        _t('Total Sets', '${data.completedSets}', Icons.repeat_rounded),
        _t('Total Reps', '${data.totalReps}', Icons.exposure_rounded),
        _t('Volume', Formatters.volumeKg(data.volume),
            Icons.straighten_rounded),
        _t('Avg Duration', Formatters.duration(data.avgDurationMinutes),
            Icons.timer_outlined),
      ],
    );
  }

  StatCard _t(String label, String value, IconData icon) =>
      StatCard(icon: icon, value: value, label: label);

  Widget _row({required List<StatCard> tiles}) {
    final rows = <Widget>[];
    final count = tiles.length;
    for (var i = 0; i < count; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: tiles[i]),
          const SizedBox(width: 10),
          Expanded(
              child: i + 1 < count ? tiles[i + 1] : const SizedBox()),
        ],
      ));
      if (i + 2 < count) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

// -------------------------------------------------------------- Strength

class StrengthProgressSection extends ConsumerWidget {
  final TimeRange range;
  final String? exerciseId;
  final ValueChanged<String> onExerciseChanged;

  const StrengthProgressSection({
    super.key,
    required this.range,
    required this.exerciseId,
    required this.onExerciseChanged,
  });

@override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiced = ref.watch(exercisesPracticedProvider);
    final selectedId = exerciseId;

    return SectionCard(
      title: 'Best weight per exercise',
      subtitle: 'Real lifts from completed workouts.',
      child: practiced.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('Failed to load exercises'),
        data: (list) {
          if (list.isEmpty) {
            return const SizedBox(
              height: 120,
              child: EmptyState(
                icon: Icons.show_chart_rounded,
                title: 'No workout data yet',
                message: 'Complete a workout to see your progress.',
              ),
            );
          }
final current = list.any((e) => e.id == selectedId)
              ? selectedId!
              : list.first.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: current,
                isDense: true,
                decoration: const InputDecoration(
                    labelText: 'Exercise',
                    border: OutlineInputBorder(),
                    isDense: true),
                items: list
                    .map((e) =>
                        DropdownMenuItem(value: e.id, child: Text(e.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onExerciseChanged(v);
                },
              ),
              const SizedBox(height: 12),
              _StrengthChart(exerciseId: current, range: range),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
builder: (_) => ExerciseProgressScreen(
                                exerciseId: current,
                                exerciseName:
                                    list.firstWhere((e) => e.id == current).name,
                              ))),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View details'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StrengthChart extends ConsumerWidget {
  final String exerciseId;
  final TimeRange range;
  const _StrengthChart({required this.exerciseId, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final points = ref.watch(strengthProgressProvider(exerciseId));
    return points.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('No data'),
      data: (all) {
        final start = range.start(DateTime.now());
        final list =
            all.where((p) => !p.date.isBefore(start)).toList();
        if (list.isEmpty) {
          return const SizedBox(
            height: 120,
            child: EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'No lifts in this range',
              message: 'Switch to All Time to view your full strength curve.',
            ),
          );
        }
        final maxWeight =
            list.map((p) => p.weight).reduce((a, b) => a > b ? a : b);
        return Column(
          children: [
            Row(
              children: [
                Text('Best lift: ${Formatters.weightKg(maxWeight)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LineChartView(
                spots: list
                    .map((p) => FlSpot(
                        p.date.millisecondsSinceEpoch.toDouble() / 86400000,
                        p.weight))
                    .toList(),
                color: theme.colorScheme.primary,
                xFormatter: (v) => DateTime.fromMillisecondsSinceEpoch(
                        (v * 86400000).round())
                    .weekdayShort,
                yFormatter: (v) => v.round().toString(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------------- Frequency

class FrequencySection extends ConsumerWidget {
  final TimeRange range;
  const FrequencySection({super.key, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = ref.watch(progressOverviewProvider(range));
    return SectionCard(
      title: 'Workouts per ${range.isDaily ? 'day' : 'week'}',
      child: overview.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('No data'),
        data: (data) {
          if (data.workouts == 0) {
            return const SizedBox(
              height: 120,
              child: EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'No workouts yet',
                message: 'Your workout frequency will build here.',
              ),
            );
          }
          final buckets = data.buckets;
          final maxV = buckets
              .map((b) => b.workouts)
              .reduce((a, b) => a > b ? a : b);
          final labelInterval =
              (buckets.length / 6).ceil().clamp(1, buckets.length);
          return SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: (maxV * 1.15).clamp(1.0, double.infinity),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final bucket = buckets[groupIndex];
                      return BarTooltipItem(
                        '${bucket.start.displayMonthDay}\n'
                        '${bucket.workouts} workout${bucket.workouts == 1 ? '' : 's'}',
                        theme.textTheme.labelSmall!
                            .copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i % labelInterval != 0 ||
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
                  horizontalInterval:
                      (maxV * 0.2).clamp(1.0, double.infinity),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].workouts.toDouble(),
                          width: range.isDaily ? 12 : 16,
                          borderRadius: BorderRadius.circular(4),
                          color: buckets[i].workouts == 0
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primary,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- Volume

class VolumeSection extends ConsumerWidget {
  final TimeRange range;
  const VolumeSection({super.key, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = ref.watch(progressOverviewProvider(range));
    return SectionCard(
      title: 'Volume per ${range.isDaily ? 'day' : 'week'}',
      child: overview.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('No data'),
        data: (data) {
          if (data.volume <= 0) {
            return const SizedBox(
              height: 120,
              child: EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'No volume yet',
                message: 'Your training volume will build here.',
              ),
            );
          }
          final buckets = data.buckets;
          final labelInterval =
              (buckets.length / 6).ceil().clamp(1, buckets.length);
          return SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final bucket = buckets[groupIndex];
                      return BarTooltipItem(
                        '${bucket.start.displayMonthDay}\n'
                        '${Formatters.volumeKg(bucket.volume)}',
                        theme.textTheme.labelSmall!
                            .copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true, reservedSize: 48),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i % labelInterval != 0 ||
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
                          toY: buckets[i].volume,
                          width: range.isDaily ? 12 : 16,
                          borderRadius: BorderRadius.circular(4),
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- Weight

class WeightProgressSection extends ConsumerWidget {
  const WeightProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final measurements = ref.watch(measurementsProvider);

    return SectionCard(
      title: 'Body weight over time',
      child: measurements.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('No data yet'),
        data: (list) {
          final withWeight =
              list.where((m) => m.weightKg != null).toList();
          if (withWeight.isEmpty) {
            return const SizedBox(
              height: 120,
              child: EmptyState(
                icon: Icons.monitor_weight_outlined,
                title: 'No weight records',
                message: 'Add a body measurement to see your weight here.',
              ),
            );
          }
          if (withWeight.length == 1) {
            final m = withWeight.first;
            return Row(
              children: [
                Text('Latest:',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                Text(Formatters.weightKg(m.weightKg),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary)),
              ],
            );
          }
          final values = withWeight.map((m) => m.weightKg!).toList();
          final minV = values.reduce((a, b) => a < b ? a : b);
          final maxV = values.reduce((a, b) => a > b ? a : b);
          return SizedBox(
            height: 140,
            child: LineChartView(
              spots: withWeight
                  .map((m) => FlSpot(
                      m.date.millisecondsSinceEpoch.toDouble() / 86400000,
                      m.weightKg!))
                  .toList(),
              color: theme.colorScheme.tertiary,
              minY: minV - 1,
              maxY: maxV + 1,
              xFormatter: (v) => DateTime.fromMillisecondsSinceEpoch(
                      (v * 86400000).round())
                  .weekdayShort,
              yFormatter: (v) => v.round().toString(),
            ),
          );
        },
      ),
    );
  }
}
