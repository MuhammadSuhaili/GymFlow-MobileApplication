import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:gym_flow/core/extensions/date_extensions.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/models/daily_check_in.dart';
import 'package:gym_flow/models/workout_day.dart';
import 'package:gym_flow/models/workout_session.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/data_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/checkin/check_in_screen.dart';
import 'package:gym_flow/screens/workout/history_detail_screen.dart';

/// Month calendar with daily indicators:
/// Calendar dots: workout done, check-in, missed workout, and rest / no data.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month; // first day of the visible month

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<Map<int, WorkoutDay>> _scheduleMap(
      WidgetRef ref, String? programId) async {
    if (programId == null) return const {};
    final weeks = await ref.watch(programWeeksProvider(programId).future);
    if (weeks.isEmpty) return const {};
    final days = await ref.watch(weekDaysProvider(weeks.first.id).future);
    return {for (final d in days) d.dayOfWeek: d};
  }

  Future<void> _openDay(
      BuildContext context, DateTime day, _DayDetail detail) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _DaySheet(
        day: day,
        detail: detail,
        onOpenWorkout: detail.session != null
            ? () => Navigator.of(sheetContext).push(MaterialPageRoute(
                  builder: (_) =>
                      HistoryDetailScreen(sessionId: detail.session!.id),
                ))
            : null,
        onCheckIn: detail.checkin == null
            ? () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CheckInScreen()));
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = ref.watch(_monthSessionsProvider(_month));
    final checkins = ref.watch(_monthCheckinsProvider(_month));
    final program = ref.watch(activeProgramProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left_rounded)),
                Text('${_month.displayMonthDay} ${_month.year}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                IconButton(
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
        ),
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (sessionList) => checkins.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed: $e')),
          data: (checkinList) {
            final byDay = _index(checkinList);
            return FutureBuilder<Map<int, WorkoutDay>>(
              future: _scheduleMap(ref, program?.id),
              builder: (context, snap) {
                final schedule = snap.data ?? const <int, WorkoutDay>{};
                final hasProgram =
                    program != null && (snap.data ?? const {}).isNotEmpty;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (final name in _weekdayLabels)
                            Expanded(
                              child: Center(
                                child: Text(name,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: _gridCount(_month),
                        itemBuilder: (context, i) {
                          final day = _gridDay(_month, i);
                          if (day == null) return const SizedBox.shrink();
                          final detail = _dayDetail(day, sessionList,
                              byDay[day.dateOnly], schedule, hasProgram);
                          return _DayCell(
                            day: day,
                            status: detail.status,
                            onTap: () => _openDay(context, day, detail),
                          );
                        },
                      ),
                    ),
                    const _Legend(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Map<DateTime, DailyCheckIn> _index(List<DailyCheckIn> checkins) => {
        for (final c in checkins) c.date.dateOnly: c,
      };

  int _gridCount(DateTime month) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final cellsBefore = firstWeekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final total = cellsBefore + daysInMonth;
    return ((total / 7).ceil() * 7);
  }

  DateTime? _gridDay(DateTime month, int index) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final day = index - (firstWeekday - 1) + 1;
    if (day < 1 || day > DateTime(month.year, month.month + 1, 0).day) {
      return null;
    }
    return DateTime(month.year, month.month, day);
  }

  _DayDetail _dayDetail(DateTime day, List<WorkoutSession> sessions,
      DailyCheckIn? checkin, Map<int, WorkoutDay> schedule, bool hasProgram) {
    final date = day.dateOnly;
    final session =
        sessions.where((s) => s.date.dateOnly == date).firstOrNull;
    final scheduled = schedule[day.weekday];
    _DayStatus status;
    if (session != null) {
      status = _DayStatus.workout;
    } else if (checkin != null) {
      status = _DayStatus.checkin;
    } else if (hasProgram && scheduled != null && !scheduled.isRest) {
      status = _DayStatus.missed;
    } else {
      status = _DayStatus.rest;
    }
    return _DayDetail(
        day: date,
        session: session,
        checkin: checkin,
        scheduled: scheduled,
        status: status);
  }
}

enum _DayStatus { workout, checkin, missed, rest }

class _DayDetail {
  final DateTime day;
  final WorkoutSession? session;
  final DailyCheckIn? checkin;
  final WorkoutDay? scheduled;
  final _DayStatus status;

  const _DayDetail({
    required this.day,
    required this.session,
    required this.checkin,
    required this.scheduled,
    required this.status,
  });
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final _DayStatus status;
  final VoidCallback onTap;

  const _DayCell(
      {required this.day, required this.status, required this.onTap});

  static Color? _dotColor(_DayStatus s, ColorScheme scheme) => switch (s) {
        _DayStatus.workout => AppColors.success,
        _DayStatus.checkin => AppColors.info,
        _DayStatus.missed => scheme.error,
        _DayStatus.rest => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day.dateOnly == DateTime.now().dateOnly;
    final color = _dotColor(status, theme.colorScheme);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? theme.colorScheme.primary : null,
            ),
            child: Text('${day.day}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                )),
          ),
          const SizedBox(height: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(Color? color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: color)),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(width: 12),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          item(AppColors.success, 'Workout'),
          item(AppColors.info, 'Check-in'),
          item(theme.colorScheme.error, 'Missed'),
          item(null, 'Rest'),
        ],
      ),
    );
  }
}

class _DaySheet extends ConsumerWidget {
  final DateTime day;
  final _DayDetail detail;
  final VoidCallback? onOpenWorkout;
  final VoidCallback? onCheckIn;

  const _DaySheet({
    required this.day,
    required this.detail,
    required this.onOpenWorkout,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checkin = detail.checkin;
    final session = detail.session;
    final scheduled = detail.scheduled;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${day.displayMonthDay} · ${day.displayWeekday}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _SheetRow(
                icon: Icons.fitness_center_rounded,
                color: AppColors.success,
                text: session != null
                    ? 'Workout completed: ${session.title}'
                    : scheduled != null && !scheduled.isRest
                        ? 'Scheduled workout: ${scheduled.title}'
                        : 'No workout recorded',
                action: onOpenWorkout != null
                    ? TextButton(
                        onPressed: onOpenWorkout,
                        child: const Text('View'))
                    : null,
              ),
              if (session != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _SessionSummary(sessionId: session.id),
                )
              else if (scheduled != null && !scheduled.isRest)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ScheduledExercises(dayId: scheduled.id),
                ),
              const SizedBox(height: 12),
              _SheetRow(
                icon: Icons.favorite_rounded,
                color: AppColors.info,
                text: checkin != null
                    ? 'Check-in: mood ${checkin.mood}/5 · '
                        'energy ${checkin.energy}/5'
                    : 'No check-in today',
                action: onCheckIn != null
                    ? TextButton(
                        onPressed: onCheckIn, child: const Text('Check in'))
                    : null,
              ),
              if (checkin?.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text('Notes: “${checkin!.notes}”',
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
}

/// Stats for a completed session shown in the calendar day sheet.
class _SessionSummary extends ConsumerWidget {
  final String sessionId;
  const _SessionSummary({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionByIdProvider(sessionId));
    final sets = ref.watch(setsBySessionProvider(sessionId));

    final items = <(String, String)>[];
    session.whenData((s) {
      if (s != null) {
        items.add(('Duration', Formatters.duration(s.durationMinutes)));
      }
    });
    sets.whenData((list) {
      final done = list.where((s) => s.completed).toList();
      var reps = 0;
      var volume = 0.0;
      for (final set in done) {
        reps += set.reps;
        volume += set.weight * set.reps;
      }
      items.add(('Sets', '${done.length}'));
      items.add(('Volume', Formatters.volumeKg(volume)));
      items.add(('Reps', '$reps'));
    });
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: theme.colorScheme.outlineVariant,
              ),
            Expanded(
              child: Column(
                children: [
                  Text(items[i].$1,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(items[i].$2,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Exercise list for a scheduled (not yet completed) day.
class _ScheduledExercises extends ConsumerWidget {
  final String dayId;
  const _ScheduledExercises({required this.dayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(dayExercisesProvider(dayId));
    return exercises.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exercises',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            ...list.take(6).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_right_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(child: Text(e.name, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  const _SheetRow({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium)),
        if (action != null) action!,
      ],
    );
  }
}

/// Workouts completed in a month.
final _monthSessionsProvider =
    FutureProvider.family<List<WorkoutSession>, DateTime>((ref, month) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(workoutRepositoryProvider).getSessionsBetween(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 0),
      );
});

/// Check-ins in a month.
final _monthCheckinsProvider =
    FutureProvider.family<List<DailyCheckIn>, DateTime>((ref, month) async {
  ref.watch(refreshTriggerProvider);
  return ref.watch(checkinRepositoryProvider).getBetween(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 0),
      );
});