import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 30,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final Widget simplePanel = Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4DCCB)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0B3D31).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );

      if (onTap == null) {
        return simplePanel;
      }

      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: simplePanel,
        ),
      );
    }

    final Widget panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.86),
                Colors.white.withValues(alpha: 0.58),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0B3D31).withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: panel,
      ),
    );
  }
}
