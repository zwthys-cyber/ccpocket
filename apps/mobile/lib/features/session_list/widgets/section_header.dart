import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  final bool shrinkTrailingToFit;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.shrinkTrailingToFit = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox.square(
              dimension: 30,
              child: Icon(icon, size: 17, color: color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            if (shrinkTrailingToFit)
              Flexible(
                flex: 2,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing!,
                ),
              ),
            if (!shrinkTrailingToFit) trailing!,
          ],
        ],
      ),
    );
  }
}
