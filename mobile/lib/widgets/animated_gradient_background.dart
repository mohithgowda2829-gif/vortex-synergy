import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return _buildBackground(0.35);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => _buildBackground(_controller.value),
    );
  }

  Widget _buildBackground(double value) {
    final Alignment begin = Alignment.lerp(
          Alignment.topLeft,
          const Alignment(-0.35, -1),
          value,
        ) ??
        Alignment.topLeft;
    final Alignment end = Alignment.lerp(
          Alignment.bottomRight,
          const Alignment(0.85, 1),
          value,
        ) ??
        Alignment.bottomRight;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: const <Color>[
            Color(0xFFDDF4EA),
            Color(0xFFFFF0C5),
            Color(0xFFF4E8D8),
            Color(0xFFE7EEF8),
          ],
          stops: const <double>[0, 0.38, 0.72, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _Orb(
            size: 260,
            color: const Color(0xFF0B6B57),
            alignment: const Alignment(-1.18, -0.88),
            dx: 28 * value,
            dy: 18 * value,
            opacity: 0.18,
          ),
          _Orb(
            size: 300,
            color: const Color(0xFFD66B1F),
            alignment: const Alignment(1.28, -0.28),
            dx: -34 * value,
            dy: 24 * value,
            opacity: 0.14,
          ),
          _Orb(
            size: 230,
            color: const Color(0xFF155E75),
            alignment: const Alignment(0.62, 1.18),
            dx: -20 * value,
            dy: -28 * value,
            opacity: 0.13,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GridPatternPainter()),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.color,
    required this.alignment,
    required this.dx,
    required this.dy,
    required this.opacity,
  });

  final double size;
  final Color color;
  final Alignment alignment;
  final double dx;
  final double dy;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF102521).withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const double gap = 34;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
