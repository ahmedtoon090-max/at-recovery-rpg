import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Paints a glowing serpentine Bezier campaign trail behind vertical Journey nodes.
class JourneyPathPainter extends CustomPainter {
  const JourneyPathPainter({
    required this.nodeCount,
    required this.unlockedCount,
    required this.rowHeight,
  });

  final int nodeCount;
  final int unlockedCount;
  final double rowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount < 2) return;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final litPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentEmeraldGlow,
          AppColors.accentCyan,
          AppColors.accentGold,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final basePath = Path();
    final litPath = Path();

    Offset centerFor(int idx) {
      final lane = _laneFraction(idx);
      final x = size.width * lane;
      final y = idx * rowHeight + rowHeight * 0.5;
      return Offset(x, y);
    }

    for (var i = 0; i < nodeCount - 1; i++) {
      final p1 = centerFor(i);
      final p2 = centerFor(i + 1);
      final midY = (p1.dy + p2.dy) / 2;

      if (i == 0) basePath.moveTo(p1.dx, p1.dy);
      basePath.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);

      if (i + 1 < unlockedCount) {
        if (i == 0) litPath.moveTo(p1.dx, p1.dy);
        litPath.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);
      }
    }

    canvas.drawPath(basePath, trackPaint);
    if (unlockedCount > 1) {
      canvas.drawPath(litPath, litPaint);
    }
  }

  static double _laneFraction(int idx) => switch (idx % 4) {
        0 => 0.50,
        1 => 0.72,
        2 => 0.50,
        _ => 0.28,
      };

  @override
  bool shouldRepaint(JourneyPathPainter old) =>
      old.nodeCount != nodeCount ||
      old.unlockedCount != unlockedCount ||
      old.rowHeight != rowHeight;
}
