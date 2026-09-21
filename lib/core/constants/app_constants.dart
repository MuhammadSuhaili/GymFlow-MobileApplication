import 'package:flutter/material.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'GymFlow';
  static const String tagline = 'Gym & Workout Management';

  // Rest timer presets (seconds).
  static const List<int> restTimerPresets = [60, 90, 120, 180];

  /// Aira chatbot endpoint (Vercel deployment live).
  static const String airaChatEndpoint =
      'https://aira-six-weld.vercel.app/api/chat';

  /// Default provider/model untuk chat. Sesuaikan bila model di Vercel berubah
  /// (cek via GET /api/bootstrap).
  static const String airaProvider = 'gemini';
  static const String airaModel = 'gemini-3.5-flash';

  // Aira quick suggestions shown in the chat panel.
  static const List<String> airaSuggestions = [
    'Buatkan program latihan untuk pemula',
    'Tips agar tidak cedera saat angkat beban',
    'Berapa banyak protein yang saya butuhkan?',
    'Latihan terbaik untuk membakar lemak',
  ];

  // Mood options: value 1..5.
  static const List<Mood> moods = [
    Mood(value: 1, emoji: '😫', label: 'Very Bad'),
    Mood(value: 2, emoji: '😕', label: 'Bad'),
    Mood(value: 3, emoji: '😐', label: 'Normal'),
    Mood(value: 4, emoji: '🙂', label: 'Good'),
    Mood(value: 5, emoji: '🔥', label: 'Excellent'),
  ];

  static const int ratingLevels = 5;
}

class Mood {
  final int value;
  final String emoji;
  final String label;

  const Mood({required this.value, required this.emoji, required this.label});

  static Mood? fromValue(int? value) {
    if (value == null) return null;
    for (final mood in AppConstants.moods) {
      if (mood.value == value) return mood;
    }
    return null;
  }
}

const List<String> fitnessGoals = [
  GymGoals.muscleBuilding,
  GymGoals.strength,
  GymGoals.fatLoss,
  GymGoals.generalFitness,
];

const List<String> experienceLevels = [
  Experience.beginner,
  Experience.intermediate,
  Experience.advanced,
];

const List<String> unitSystems = ['Metric (kg)', 'Imperial (lb)'];

/// Quick-pick names for a non-rest workout day.
const List<String> workoutTitles = [
  'Push',
  'Pull',
  'Legs',
  'Upper',
  'Lower',
  'Full Body',
  'Cardio',
];

class GymGoals {
  static const String muscleBuilding = 'Muscle Building';
  static const String strength = 'Strength';
  static const String fatLoss = 'Fat Loss';
  static const String generalFitness = 'General Fitness';

  static const Map<String, IconData> icons = {
    muscleBuilding: Icons.fitness_center,
    strength: Icons.sports_gymnastics,
    fatLoss: Icons.local_fire_department,
    generalFitness: Icons.directions_run,
  };
}

class Experience {
  static const String beginner = 'Beginner';
  static const String intermediate = 'Intermediate';
  static const String advanced = 'Advanced';
}

const List<String> muscleGroups = [
  'Chest',
  'Back',
  'Shoulder',
  'Biceps',
  'Triceps',
  'Legs',
  'Glutes',
  'Core',
  'Cardio',
];

const List<String> equipments = [
  'Barbell',
  'Dumbbell',
  'Cable',
  'Machine',
  'Bodyweight',
  'Kettlebell',
];

class Difficulty {
  static const String beginner = 'Beginner';
  static const String intermediate = 'Intermediate';
  static const String advanced = 'Advanced';
}

class PreferencesKeys {
  static const String themeMode = 'theme_mode';
  static const String unitSystem = 'unit_system';
  static const String notificationsEnabled = 'notifications_enabled';
}
