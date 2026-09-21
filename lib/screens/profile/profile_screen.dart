import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/models/user.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/providers/program_providers.dart';
import 'package:gym_flow/providers/settings_providers.dart';
import 'package:gym_flow/screens/calendar/calendar_screen.dart';
import 'package:gym_flow/screens/profile/notification_settings_screen.dart';
import 'package:gym_flow/screens/progress/measurements_screen.dart';
import 'package:gym_flow/screens/progress/progress_screen.dart';
import 'package:gym_flow/screens/report/monthly_report_screen.dart';
import 'package:gym_flow/screens/workout/history_screen.dart';
import 'package:gym_flow/widgets/app_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          user.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load profile: $e'),
            data: (profile) => _ProfileCard(
              user: profile,
              unit: unit,
              onEdit: () => _openEditProfile(context, profile),
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.show_chart_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Progress'),
              subtitle: const Text('Statistics, charts and exercise progress'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.straighten_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Body Measurements'),
              subtitle: const Text(
                'Weight, body fat and circumference history',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Workout History'),
              subtitle: const Text('View past sessions and details'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_view_month_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Monthly Report'),
              subtitle: const Text('Workouts, volume and body by month'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_month_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Calendar'),
              subtitle: const Text(
                'Scheduled, completed, missed and rest days',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const SettingsSection(),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context, User profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileEditScreen(user: profile)),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;
  final String unit;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.user,
    required this.unit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty
                    ? user.name.substring(0, 1).toUpperCase()
                    : '?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.age} yrs • ${user.heightCm} cm • $unit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.goal} • ${user.experience}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
        ],
      ),
    );
  }
}

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitSystemProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Workout and check-in reminders'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.straighten_rounded),
            title: const Text('Unit System'),
            subtitle: Text(unit),
            onTap: () => _pickUnit(context, ref, unit),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _pickTheme(context, ref, themeMode),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Data Backup'),
            subtitle: const Text('Export your data as a JSON snapshot'),
            onTap: () => _exportBackup(context, ref),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.delete_forever_rounded),
            title: const Text('Reset Data'),
            subtitle: const Text('Erase all programs, workouts and records'),
            textColor: Theme.of(context).colorScheme.error,
            onTap: () => _resetData(context, ref),
          ),
        ),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _pickUnit(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Unit System'),
        children: unitSystems
            .map(
              (u) => RadioListTile<String>(
                value: u,
                groupValue: current,
                onChanged: (v) => Navigator.pop(context, v),
                title: Text(u),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null)
      await ref.read(unitSystemProvider.notifier).set(selected);
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: ThemeMode.values
            .map(
              (m) => RadioListTile<ThemeMode>(
                value: m,
                groupValue: current,
                onChanged: (v) => Navigator.pop(context, v),
                title: Text(_themeLabel(m)),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null)
      await ref.read(themeModeProvider.notifier).set(selected);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final json = await ref.read(settingsRepositoryProvider).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup copied to clipboard (JSON)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This permanently deletes every program, workout, check-in and measurement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(settingsRepositoryProvider).resetAllData();
      ref.read(refreshTriggerProvider.notifier).bump();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.user});

  final User user;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late String _goal;
  late String _experience;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    final unit = ref.read(unitSystemProvider);
    _name = TextEditingController(text: u.name);
    _age = TextEditingController(text: u.age.toString());
    _height = TextEditingController(text: u.heightCm.toString());
    _weight = TextEditingController(
      text: _displayWeight(unit, u.weightKg).toString(),
    );
    _goal = u.goal;
    _experience = u.experience;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double _displayWeight(String unit, double kg) {
    if (unit == unitSystems[1]) return (kg * 2.20462);
    return kg;
  }

  double _storeWeight(String unit, double displayed) {
    if (unit == unitSystems[1]) return (displayed / 2.20462);
    return displayed;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final unit = ref.read(unitSystemProvider);
    final weightKg = _storeWeight(
      unit,
      double.tryParse(_weight.text.trim()) ?? widget.user.weightKg,
    );
    final updated = widget.user.copyWith(
      name: _name.text.trim(),
      age: int.tryParse(_age.text.trim()) ?? widget.user.age,
      heightCm: double.tryParse(_height.text.trim()) ?? widget.user.heightCm,
      weightKg: weightKg,
      goal: _goal,
      experience: _experience,
    );
    await ref.read(userRepositoryProvider).save(updated);
    ref.read(refreshTriggerProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(unitSystemProvider);
    final roomierFields = theme.inputDecorationTheme.copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        top: false,
        child: Theme(
          data: theme.copyWith(inputDecorationTheme: roomierFields),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) =>
                        (v == null || (int.tryParse(v) ?? -1) < 1)
                        ? 'Valid age required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      suffixText: 'cm',
                    ),
                    validator: (v) =>
                        (v == null || (double.tryParse(v) ?? -1) < 1)
                        ? 'Valid height required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: unit == unitSystems[1] ? 'lb' : 'kg',
                    ),
                    validator: (v) =>
                        (v == null || (double.tryParse(v) ?? -1) < 1)
                        ? 'Valid weight required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _goal,
                    decoration: const InputDecoration(
                      labelText: 'Fitness Goal',
                    ),
                    items: fitnessGoals
                        .map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _goal = v ?? _goal),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _experience,
                    decoration: const InputDecoration(
                      labelText: 'Experience',
                    ),
                    items: experienceLevels
                        .map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _experience = v ?? _experience),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Profile'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
