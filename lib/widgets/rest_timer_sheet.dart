import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/core/utils/formatters.dart';

/// Modal rest timer with presets, pause, skip and +30s.
class RestTimerSheet extends StatefulWidget {
  final int initialSeconds;

  const RestTimerSheet({super.key, this.initialSeconds = 90});

  /// Shows the timer as a modal bottom sheet; resolves when the user closes it.
  static Future<void> show(BuildContext context, {int initialSeconds = 90}) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => RestTimerSheet(initialSeconds: initialSeconds),
    );
  }

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  late int _remaining = widget.initialSeconds;
  late int _total = widget.initialSeconds;
  Timer? _timer;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining--;
        if (_remaining == 0) {
          timer.cancel();
          _running = false;
          _onComplete();
        }
      });
    });
  }

  void _onComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rest complete. Ready for your next set?'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _running = !_running;
      if (_running) {
        _start();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _skip() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  void _addSeconds(int seconds) {
    _timer?.cancel();
    setState(() {
      _remaining += seconds;
      _total = _remaining;
    });
    if (!_running) {
      setState(() => _running = true);
    }
    _start();
  }

  void _setPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _remaining = seconds;
      _total = seconds;
      _running = true;
    });
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _total == 0 ? 1.0 : (_remaining / _total).clamp(0.0, 1.0);
    final color = _remaining <= 10 ? theme.colorScheme.error : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _remaining == 0 ? 'Rest Complete!' : 'Rest',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Formatters.seconds(_remaining),
                        style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontSize: 44)),
                    const SizedBox(height: 4),
                    Text('Ready for your next set?',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _togglePause,
                icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                tooltip: _running ? 'Pause' : 'Resume',
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _addSeconds(30),
                style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    foregroundColor: theme.colorScheme.onTertiaryContainer),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add 30 seconds',
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _skip,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'Skip',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: AppConstants.restTimerPresets.map((seconds) {
              final selected = _total == seconds;
              return ChoiceChip(
                label: Text('${seconds}s'),
                selected: selected,
                onSelected: (_) => _setPreset(seconds),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}