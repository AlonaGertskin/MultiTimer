import 'package:flutter/material.dart';

class EmptyListMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final InlineSpan hint;

  const EmptyListMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: soft.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text.rich(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: soft),
            ),
          ],
        ),
      ),
    );
  }
}
