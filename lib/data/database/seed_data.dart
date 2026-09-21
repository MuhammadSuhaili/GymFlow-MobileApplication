import 'package:gym_flow/models/exercise.dart';
import 'package:gym_flow/models/user.dart';

class UserSeed {
  UserSeed._();
  static final User defaultUser = User.defaults();
}

/// The built-in exercise library seeded into the database on first launch.
class SeedData {
  SeedData._();

  static const List<Exercise> exercises = [
    // Chest
    Exercise(
      id: 'ex_barbell_bench_press',
      name: 'Barbell Bench Press',
      primaryMuscle: 'Chest',
      secondaryMuscle: 'Triceps, Shoulder',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Lie on a flat bench, grip the bar slightly wider than shoulder width, lower it to mid-chest and press up.',
    ),
    Exercise(
      id: 'ex_dumbbell_bench_press',
      name: 'Dumbbell Bench Press',
      primaryMuscle: 'Chest',
      secondaryMuscle: 'Triceps, Shoulder',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Press two dumbbells from your chest to arms fully extended while lying on a bench.',
    ),
    Exercise(
      id: 'ex_incline_dumbbell_press',
      name: 'Incline Dumbbell Press',
      primaryMuscle: 'Chest',
      secondaryMuscle: 'Shoulder, Triceps',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Set a bench to 30-45 degrees, press dumbbells up focusing on the upper chest.',
    ),
    Exercise(
      id: 'ex_cable_fly',
      name: 'Cable Fly',
      primaryMuscle: 'Chest',
      secondaryMuscle: 'Shoulder',
      equipment: 'Cable',
      difficulty: 'Beginner',
      instructions:
          'With cables set at chest height, bring hands together in front of the chest and return slowly.',
    ),
    Exercise(
      id: 'ex_push_up',
      name: 'Push Up',
      primaryMuscle: 'Chest',
      secondaryMuscle: 'Triceps, Shoulder, Core',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      instructions:
          'Keep the body straight and lower your chest towards the floor, then press back up.',
    ),

    // Back
    Exercise(
      id: 'ex_deadlift',
      name: 'Deadlift',
      primaryMuscle: 'Back',
      secondaryMuscle: 'Glutes, Legs, Core',
      equipment: 'Barbell',
      difficulty: 'Advanced',
      instructions:
          'Hinge at the hips, grip the bar, keep a flat back and stand up with the bar.',
    ),
    Exercise(
      id: 'ex_barbell_row',
      name: 'Barbell Row',
      primaryMuscle: 'Back',
      secondaryMuscle: 'Biceps, Rear Delts',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Bend over with a flat back and row the bar to your lower chest.',
    ),
    Exercise(
      id: 'ex_pull_up',
      name: 'Pull Up',
      primaryMuscle: 'Back',
      secondaryMuscle: 'Biceps',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      instructions:
          'Hang from a bar with an overhand grip and pull your chin above the bar.',
    ),
    Exercise(
      id: 'ex_lat_pulldown',
      name: 'Lat Pulldown',
      primaryMuscle: 'Back',
      secondaryMuscle: 'Biceps',
      equipment: 'Cable',
      difficulty: 'Beginner',
      instructions:
          'Pull the bar down to your upper chest while keeping your torso upright.',
    ),
    Exercise(
      id: 'ex_seated_cable_row',
      name: 'Seated Cable Row',
      primaryMuscle: 'Back',
      secondaryMuscle: 'Biceps, Rear Delts',
      equipment: 'Cable',
      difficulty: 'Beginner',
      instructions:
          'Sit upright and pull the handle towards your abdomen, squeezing the shoulder blades.',
    ),

    // Shoulder
    Exercise(
      id: 'ex_overhead_press',
      name: 'Overhead Press (OHP)',
      primaryMuscle: 'Shoulder',
      secondaryMuscle: 'Triceps',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Press the bar overhead from shoulder level until arms are extended.',
    ),
    Exercise(
      id: 'ex_dumbbell_shoulder_press',
      name: 'Dumbbell Shoulder Press',
      primaryMuscle: 'Shoulder',
      secondaryMuscle: 'Triceps',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Press dumbbells overhead from a seated or standing position.',
    ),
    Exercise(
      id: 'ex_lateral_raise',
      name: 'Lateral Raise',
      primaryMuscle: 'Shoulder',
      secondaryMuscle: 'Traps',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Raise dumbbells to the sides until arms are parallel to the floor.',
    ),
    Exercise(
      id: 'ex_face_pull',
      name: 'Face Pull',
      primaryMuscle: 'Shoulder',
      secondaryMuscle: 'Rear Delts, Upper Back',
      equipment: 'Cable',
      difficulty: 'Beginner',
      instructions:
          'Pull the rope towards your face, flaring your elbows and squeezing rear delts.',
    ),

    // Biceps
    Exercise(
      id: 'ex_barbell_curl',
      name: 'Barbell Curl',
      primaryMuscle: 'Biceps',
      secondaryMuscle: 'Forearms',
      equipment: 'Barbell',
      difficulty: 'Beginner',
      instructions:
          'Curl the bar from full extension to a full contraction of the biceps.',
    ),
    Exercise(
      id: 'ex_dumbbell_curl',
      name: 'Dumbbell Curl',
      primaryMuscle: 'Biceps',
      secondaryMuscle: 'Forearms',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Curl one or both dumbbells with controlled tempo, squeezing at the top.',
    ),
    Exercise(
      id: 'ex_hammer_curl',
      name: 'Hammer Curl',
      primaryMuscle: 'Biceps',
      secondaryMuscle: 'Brachialis, Forearms',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Curl with a neutral grip (palms facing in) to emphasize the brachialis.',
    ),

    // Triceps
    Exercise(
      id: 'ex_skull_crusher',
      name: 'Skull Crusher',
      primaryMuscle: 'Triceps',
      secondaryMuscle: 'Chest',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Lower the bar towards your forehead keeping upper arms still, then extend.',
    ),
    Exercise(
      id: 'ex_triceps_pushdown',
      name: 'Triceps Pushdown',
      primaryMuscle: 'Triceps',
      secondaryMuscle: 'None',
      equipment: 'Cable',
      difficulty: 'Beginner',
      instructions:
          'Push the cable attachment down until arms are fully extended.',
    ),
    Exercise(
      id: 'ex_overhead_triceps_extension',
      name: 'Overhead Triceps Extension',
      primaryMuscle: 'Triceps',
      secondaryMuscle: 'None',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Lower a dumbbell behind your head and extend back up with both hands.',
    ),

    // Legs
    Exercise(
      id: 'ex_squat',
      name: 'Barbell Back Squat',
      primaryMuscle: 'Legs',
      secondaryMuscle: 'Glutes, Core',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Squat down with the bar on your upper back until thighs are parallel, then stand up.',
    ),
    Exercise(
      id: 'ex_front_squat',
      name: 'Front Squat',
      primaryMuscle: 'Legs',
      secondaryMuscle: 'Glutes, Core, Upper Back',
      equipment: 'Barbell',
      difficulty: 'Advanced',
      instructions:
          'Hold the bar on your front shoulders and squat keeping elbows high.',
    ),
    Exercise(
      id: 'ex_leg_press',
      name: 'Leg Press',
      primaryMuscle: 'Legs',
      secondaryMuscle: 'Glutes',
      equipment: 'Machine',
      difficulty: 'Beginner',
      instructions:
          'Press the platform away with your feet and lower with control.',
    ),
    Exercise(
      id: 'ex_leg_extension',
      name: 'Leg Extension',
      primaryMuscle: 'Legs',
      secondaryMuscle: 'None',
      equipment: 'Machine',
      difficulty: 'Beginner',
      instructions:
          'Extend your knees against the pad to isolate the quads.',
    ),
    Exercise(
      id: 'ex_leg_curl',
      name: 'Leg Curl',
      primaryMuscle: 'Legs',
      secondaryMuscle: 'Hamstrings',
      equipment: 'Machine',
      difficulty: 'Beginner',
      instructions:
          'Curl your heels towards your glutes to target the hamstrings.',
    ),
    Exercise(
      id: 'ex_lunge',
      name: 'Dumbbell Lunge',
      primaryMuscle: 'Legs',
      secondaryMuscle: 'Glutes',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      instructions:
          'Step forward into a lunge and push back up, alternating legs.',
    ),

    // Glutes
    Exercise(
      id: 'ex_hip_thrust',
      name: 'Hip Thrust',
      primaryMuscle: 'Glutes',
      secondaryMuscle: 'Hamstrings',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'With shoulders on a bench, thrust the bar up by extending your hips.',
    ),
    Exercise(
      id: 'ex_romanian_deadlift',
      name: 'Romanian Deadlift',
      primaryMuscle: 'Glutes',
      secondaryMuscle: 'Hamstrings, Back',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      instructions:
          'Hinge at the hips and lower the bar along your legs, keeping a slight knee bend.',
    ),
    Exercise(
      id: 'ex_glute_bridge',
      name: 'Glute Bridge',
      primaryMuscle: 'Glutes',
      secondaryMuscle: 'Core',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      instructions:
          'Lie on your back, raise your hips and squeeze the glutes at the top.',
    ),

    // Core
    Exercise(
      id: 'ex_plank',
      name: 'Plank',
      primaryMuscle: 'Core',
      secondaryMuscle: 'Shoulder, Glutes',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      instructions:
          'Hold a straight-line position on your forearms and toes for time.',
    ),
    Exercise(
      id: 'ex_crunch',
      name: 'Crunch',
      primaryMuscle: 'Core',
      secondaryMuscle: 'None',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      instructions:
          'Curl your shoulders off the floor, squeezing the abs.',
    ),
    Exercise(
      id: 'ex_hanging_leg_raise',
      name: 'Hanging Leg Raise',
      primaryMuscle: 'Core',
      secondaryMuscle: 'Hip Flexors',
      equipment: 'Bodyweight',
      difficulty: 'Advanced',
      instructions:
          'Hang from a bar and raise your legs until your hips fold.',
    ),

    // Cardio
    Exercise(
      id: 'ex_treadmill_run',
      name: 'Treadmill Run',
      primaryMuscle: 'Cardio',
      secondaryMuscle: 'Legs',
      equipment: 'Machine',
      difficulty: 'Beginner',
      instructions: 'Run or jog at a steady comfortable pace.',
    ),
    Exercise(
      id: 'ex_burpee',
      name: 'Burpee',
      primaryMuscle: 'Cardio',
      secondaryMuscle: 'Chest, Legs, Core',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      instructions:
          'Squat, kick back to a plank, do a push-up, return and jump up.',
    ),
    Exercise(
      id: 'ex_stationary_bike',
      name: 'Stationary Bike',
      primaryMuscle: 'Cardio',
      secondaryMuscle: 'Legs',
      equipment: 'Machine',
      difficulty: 'Beginner',
      instructions: 'Cycle at a steady pace keeping resistance moderate.',
    ),
  ];

  /// YouTube demo videos (verified embeddable) keyed by exercise id.
  ///
  /// Stored in the `video_url` column at seed/migration time and shown on the
  /// exercise detail page. Videos come from stable fitness channels
  /// (mainly ScottHermanFitness).
  static const Map<String, String> videoUrls = {
    'ex_barbell_bench_press': 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
    'ex_dumbbell_bench_press': 'https://www.youtube.com/watch?v=Y_7aHqXeCfQ',
    'ex_incline_dumbbell_press': 'https://www.youtube.com/watch?v=hChjZQhX1Ls',
    'ex_cable_fly': 'https://www.youtube.com/watch?v=Iwe6AmxVf7o',
    'ex_push_up': 'https://www.youtube.com/watch?v=0GsVJsS6474',
    'ex_deadlift': 'https://www.youtube.com/watch?v=MBbyAqvTNkU',
    'ex_barbell_row': 'https://www.youtube.com/watch?v=9efgcAjQe7E',
    'ex_pull_up': 'https://www.youtube.com/watch?v=ylVmNQlKdAI',
    'ex_lat_pulldown': 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
    'ex_seated_cable_row': 'https://www.youtube.com/watch?v=7o2oolbmzeI',
    'ex_overhead_press': 'https://www.youtube.com/watch?v=oBGeXxnigsQ',
    'ex_dumbbell_shoulder_press': 'https://www.youtube.com/watch?v=qEwKCR5JCog',
    'ex_lateral_raise': 'https://www.youtube.com/watch?v=3VcKaXpzqRo',
    'ex_face_pull': 'https://www.youtube.com/watch?v=rep-qVOkqgk',
    'ex_barbell_curl': 'https://www.youtube.com/watch?v=QZEqB6wUPxQ',
    'ex_dumbbell_curl': 'https://www.youtube.com/watch?v=sAq_ocpRh_I',
    'ex_hammer_curl': 'https://www.youtube.com/watch?v=zC3nLlEvin4',
    'ex_skull_crusher': 'https://www.youtube.com/watch?v=ir5PsbniVSc',
    'ex_triceps_pushdown': 'https://www.youtube.com/watch?v=vB5OHsJ3EME',
    'ex_overhead_triceps_extension':
        'https://www.youtube.com/watch?v=-Vyt2QdsR7E',
    'ex_squat': 'https://www.youtube.com/watch?v=1oed-UmAxFs',
    'ex_front_squat': 'https://www.youtube.com/watch?v=tlfahNdNPPI',
    'ex_leg_press': 'https://www.youtube.com/watch?v=IZxyjW7MPJQ',
    'ex_leg_extension': 'https://www.youtube.com/watch?v=YyvSfVjQeL0',
    'ex_leg_curl': 'https://www.youtube.com/watch?v=1Tq3QdYUuHs',
    'ex_lunge': 'https://www.youtube.com/watch?v=D7KaRcUTQeE',
    'ex_hip_thrust': 'https://www.youtube.com/watch?v=SEdqd1n0cvg',
    'ex_romanian_deadlift': 'https://www.youtube.com/watch?v=JCXUYuzwNrM',
    'ex_glute_bridge': 'https://www.youtube.com/watch?v=0od5lwWMGV8',
    'ex_plank': 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
    'ex_crunch': 'https://www.youtube.com/watch?v=Xyd_fa5zoEU',
    'ex_hanging_leg_raise': 'https://www.youtube.com/watch?v=X-ACS9vpRyU',
    'ex_treadmill_run': 'https://www.youtube.com/watch?v=LnNse_AwPyE',
    'ex_burpee': 'https://www.youtube.com/watch?v=wS4OsJ4yzx4',
    'ex_stationary_bike': 'https://www.youtube.com/watch?v=NwwDBARCGgo',
  };

  static String? videoUrlFor(String id) => videoUrls[id];
}