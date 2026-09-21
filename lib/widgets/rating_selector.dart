import 'package:flutter/material.dart';

/// A 1..5 scale selector rendered as tappable pills.
class RatingSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  final String? Function(int)? labelFor;
  final bool compact;

  const RatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelFor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final v = i + 1;
        final selected = value == v;
        final label = labelFor?.call(v);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: Container(
              height: compact ? 40 : 48,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: selected
                    ? null
                    : Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
              ),
              child: label != null
                  ? Text(label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ))
                  : Text('$v',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      )),
            ),
          ),
        );
      }),
    );
  }
}

/// Displays a 1..5 scale with descriptive labels for the selection.
class RatingScaleLabel extends StatelessWidget {
  final int? value;
  final List<String> labels;
  final Widget Function()? origin;
  final String? Function(int)? tag;

  const RatingScaleLabel({
    super.key,
    required this.value,
    required this.labels,
    this.tag,
    this.origin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = value ?? 0;
    final hasLabel = current >= 1 && current <= labels.length;
    final label = hasLabel ? labels[current - 1] : '—';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(labels.first,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: current == 0
                    ? theme.colorScheme.onSurfaceVariant
                    : hasLabel
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant)),
        Text(labels.last,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}