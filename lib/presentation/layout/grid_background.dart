import 'package:flutter/material.dart';

class GridBackground extends StatelessWidget {
  const GridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GridPainter(context: context),
        child:
            Container(), // Fills available space and lets painter draw behind
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final BuildContext context;

  _GridPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Line color matches the CSS:
    // Light: #80808012 (gray at ~7% opacity)
    // Dark: #ffffff05 (white at ~2% opacity)
    final Color lineColor = isDark
        ? Colors.white.withValues(
            alpha: 0.05,
          ) // Slightly boosted from 0.02 for mobile visibility
        : const Color(0xFF808080).withValues(alpha: 0.05);

    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const double gridSize = 24.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    // Only repaint if theme brightness changes (which recreates the widget anyway)
    return false;
  }
}
