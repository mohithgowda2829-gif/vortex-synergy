import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color iconColor = highlight ? colors.primary : colors.tertiary;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 116 || constraints.maxWidth < 200;
        final double iconBoxSize = compact ? 36 : 42;
        final double iconSize = compact ? 18 : 22;
        final double gap = compact ? 8 : 14;
        final EdgeInsetsGeometry padding = EdgeInsets.all(compact ? 12 : 16);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.96, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double scale, Widget? child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlight
                    ? <Color>[const Color(0xFF0B6B57), const Color(0xFF154D5B)]
                    : <Color>[Colors.white.withValues(alpha: 0.98), const Color(0xFFFFFAEF)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: (highlight ? colors.primary : const Color(0xFF0B3D31)).withValues(alpha: 0.11),
                  blurRadius: 26,
                  offset: const Offset(0, 13),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                if (highlight)
                  Positioned(
                    right: -26,
                    top: -26,
                    child: Icon(
                      icon,
                      size: 118,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                Padding(
                  padding: padding,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: highlight ? Colors.white : null),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: iconBoxSize,
                          height: iconBoxSize,
                          decoration: BoxDecoration(
                            color: highlight
                                ? Colors.white.withValues(alpha: 0.18)
                                : iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(compact ? 12 : 14),
                          ),
                          child: Icon(icon, color: highlight ? Colors.white : iconColor, size: iconSize),
                        ),
                        SizedBox(height: gap),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: (compact
                                    ? Theme.of(context).textTheme.titleLarge
                                    : Theme.of(context).textTheme.headlineSmall)
                                ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: highlight ? Colors.white : const Color(0xFF102521),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              label,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: highlight
                                        ? Colors.white.withValues(alpha: 0.86)
                                        : const Color(0xFF44524E),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
