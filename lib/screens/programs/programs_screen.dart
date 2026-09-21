import 'package:flutter/material.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/models/program.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/screens/checkin/check_in_history_screen.dart';
import 'package:gym_flow/screens/programs/program_detail_screen.dart';
import 'package:gym_flow/screens/programs/program_form_screen.dart';
import 'package:gym_flow/widgets/empty_state.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final programs = ref.watch(programsProvider);
    final active = ref.watch(activeProgramProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_outlined),
            tooltip: 'Check-in history',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CheckInHistoryScreen())),
          ),
        ],
      ),
      floatingActionButton: programs.valueOrNull?.isEmpty ?? true
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createProgram(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Program'),
            ),
      body: programs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load programs: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No active program yet.',
              message:
                  'Create your first program to start tracking your training.',
              actionLabel: 'Create Program',
              onAction: () => _createProgram(context),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              if (active.valueOrNull != null)
                _ActiveProgramBanner(program: active.valueOrNull!),
              if (active.valueOrNull != null) const SizedBox(height: 14),
              Text('All Programs',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...list.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProgramTile(
                      program: p,
                      isActive: active.valueOrNull?.id == p.id,
                      onActivate: () async {
                        await ref
                            .read(programRepositoryProvider)
                            .setActive(p.id);
                        ref.read(refreshTriggerProvider.notifier).bump();
                      },
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProgramFormScreen(program: p),
                        ),
                      ),
                      onDelete: () => _confirmDelete(context, ref, p),
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProgramDetailScreen(program: p),
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _createProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgramFormScreen()),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Program program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete program?'),
        content: Text(
            '${program.name} and all its schedules will be permanently removed.'),
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
      await ref.read(programRepositoryProvider).deleteProgram(program.id);
      ref.read(refreshTriggerProvider.notifier).bump();
    }
  }
}

class _ActiveProgramBanner extends StatelessWidget {
  final Program program;

  const _ActiveProgramBanner({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTIVE PROGRAM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                Text(program.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final Program program;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _ProgramTile({
    required this.program,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      GymGoals.icons[program.goal] ?? Icons.fitness_center,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(program.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(program.goal,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('ACTIVE',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Meta(label: 'Duration', value: '${program.durationWeeks} weeks'),
                  const SizedBox(width: 20),
                  _Meta(label: 'Schedule', value: '7 days'),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'activate':
                          onActivate();
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isActive)
                        const PopupMenuItem(
                            value: 'activate',
                            child: Text('Activate')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
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

class _Meta extends StatelessWidget {
  final String label;
  final String value;

  const _Meta({required this.label, required this.value});

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