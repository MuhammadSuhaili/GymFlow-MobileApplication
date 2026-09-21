/// A built-in workout template that can seed a program schedule.
class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final int daysPerWeek;
  /// dayOfWeek (1=Mon..7=Sun) -> workout title, or null for rest.
  final Map<int, String?> schedule;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.daysPerWeek,
    required this.schedule,
  });

  static const fullBody = WorkoutTemplate(
    id: 'full_body',
    name: 'Full Body',
    description: 'Train every major muscle group 3x per week.',
    daysPerWeek: 3,
    schedule: {
      1: 'Full Body',
      2: null,
      3: 'Full Body',
      4: null,
      5: 'Full Body',
      6: null,
      7: null,
    },
  );

  static const upperLower = WorkoutTemplate(
    id: 'upper_lower',
    name: 'Upper Lower',
    description: 'Split your training into upper and lower body days.',
    daysPerWeek: 4,
    schedule: {
      1: 'Upper',
      2: 'Lower',
      3: null,
      4: 'Upper',
      5: 'Lower',
      6: null,
      7: null,
    },
  );

  static const pushPullLegs = WorkoutTemplate(
    id: 'push_pull_legs',
    name: 'Push Pull Legs',
    description: 'A classic 6-day split for hypertrophy and strength.',
    daysPerWeek: 6,
    schedule: {
      1: 'Push',
      2: 'Pull',
      3: 'Legs',
      4: 'Push',
      5: 'Pull',
      6: 'Legs',
      7: null,
    },
  );

  static const custom = WorkoutTemplate(
    id: 'custom',
    name: 'Custom',
    description: 'Build your own schedule from scratch.',
    daysPerWeek: 0,
    schedule: {},
  );

  static const List<WorkoutTemplate> all = [fullBody, upperLower, pushPullLegs];
  static const List<WorkoutTemplate> creatable = [custom, ...all];

  static WorkoutTemplate byId(String? id) {
    for (final t in creatable) {
      if (t.id == id) return t;
    }
    return custom;
  }
}