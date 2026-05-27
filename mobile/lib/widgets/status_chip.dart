import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.status,
  });

  final String label;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final _StatusPalette palette = _resolvePalette(context, status ?? label);
    final IconData icon = _resolveIcon(status ?? label);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.foreground.withValues(alpha: 0.13)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.foreground.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: palette.foreground, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  _StatusPalette _resolvePalette(BuildContext context, String value) {
    final String normalized = value.toUpperCase();
    if (normalized.contains('APPROVED') || normalized.contains('DELIVERED') || normalized.contains('CLAIMED')) {
      return const _StatusPalette(Color(0xFFE6F6EA), Color(0xFF0B6B2A));
    }
    if (normalized.contains('PENDING') || normalized.contains('RESERVED') || normalized.contains('TRANSIT')) {
      return const _StatusPalette(Color(0xFFFFF4DB), Color(0xFF9A6700));
    }
    if (normalized.contains('FAILED') || normalized.contains('REJECTED') || normalized.contains('CANCELLED') || normalized.contains('EXPIRED')) {
      return const _StatusPalette(Color(0xFFFFE7E4), Color(0xFFB42318));
    }
    return _StatusPalette(
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      Theme.of(context).colorScheme.primary,
    );
  }

  IconData _resolveIcon(String value) {
    final String normalized = value.toUpperCase();
    if (normalized.contains('APPROVED') || normalized.contains('DELIVERED') || normalized.contains('CLAIMED')) {
      return Icons.check_circle_rounded;
    }
    if (normalized.contains('PENDING') || normalized.contains('RESERVED') || normalized.contains('TRANSIT')) {
      return Icons.schedule_rounded;
    }
    if (normalized.contains('FAILED') || normalized.contains('REJECTED') || normalized.contains('CANCELLED') || normalized.contains('EXPIRED')) {
      return Icons.error_rounded;
    }
    return Icons.info_rounded;
  }
}

class _StatusPalette {
  const _StatusPalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
