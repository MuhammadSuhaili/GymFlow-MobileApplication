import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/core/theme/app_theme.dart';
import 'package:gym_flow/providers/settings_providers.dart';
import 'package:gym_flow/screens/main_shell.dart';
import 'package:gym_flow/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: GymFlowApp()));
}

class GymFlowApp extends ConsumerStatefulWidget {
  const GymFlowApp({super.key});

  @override
  ConsumerState<GymFlowApp> createState() => _GymFlowAppState();
}

class _GymFlowAppState extends ConsumerState<GymFlowApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeModeProvider.notifier).load();
      ref.read(unitSystemProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}