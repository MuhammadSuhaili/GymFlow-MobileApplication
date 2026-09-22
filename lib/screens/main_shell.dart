import 'package:flutter/material.dart';
import 'package:gym_flow/screens/chat/aira_chat_screen.dart';
import 'package:gym_flow/screens/exercises/exercise_library_screen.dart';
import 'package:gym_flow/screens/home/home_screen.dart';
import 'package:gym_flow/screens/profile/profile_screen.dart';
import 'package:gym_flow/screens/programs/programs_screen.dart';

/// Root scaffold with the 4-tab bottom navigation (Phase 1).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    ProgramsScreen(),
    ExerciseLibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _index, children: _tabs)),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAiraChat,
        tooltip: 'Tanya Aira',
        child: const Icon(Icons.chat_bubble_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.view_list_outlined),
              selectedIcon: Icon(Icons.view_list_rounded),
              label: 'Programs'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Exercises'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }

  void _openAiraChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiraChatSheet(),
    );
  }
}