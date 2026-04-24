import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:white_board/src/home/board/board.dart';
import 'package:white_board/src/home/drawing_path/drawing_path.dart';

class BoardPainter extends CustomPainter {
  final List<DrawingPath> paths;

  BoardPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // ..strokeCap = StrokeCap.round
    // ..strokeWidth = strokeWidth;
    Color pinkLight(double lightness) {
      return HSLColor.fromColor(Colors.pink).withLightness(lightness).toColor();
    }

    for (final path in paths) {
      paint.color = path.color;
      paint.strokeWidth = path.strokeWidth;
      paint.style = (path.isFilled == true)
          ? PaintingStyle.fill
          : PaintingStyle.stroke;
      paint.strokeCap = StrokeCap.round;
      paint.isAntiAlias = true;

      if (path.type == BoardTool.shape && path.shapeType != ShapeType.none) {
        if (path.points.length < 2) continue;
        final start = path.points.first;
        final end = path.points.last;
        final rect = Rect.fromPoints(start, end);

        switch (path.shapeType) {
          case ShapeType.rectangle:
            canvas.drawRect(rect, paint);
            break;
          case ShapeType.square:
            final side = math.min(rect.width, rect.height);
            final squareRect = Rect.fromLTWH(
              start.dx,
              start.dy,
              rect.width < 0 ? -side : side,
              rect.height < 0 ? -side : side,
            );
            canvas.drawRect(squareRect, paint);
            break;
          case ShapeType.circle:
            final radius = (end - start).distance / 2;
            final center = (start + end) / 2;
            canvas.drawCircle(center, radius, paint);
            break;
          case ShapeType.line:
            canvas.drawLine(start, end, paint);
            break;
          case ShapeType.arrow:
            _drawArrow(canvas, start, end, paint);
            break;
          case ShapeType.polygon:
            // For now simple triangle or just draw points
            if (path.points.length > 2) {
              final polyPath = Path()
                ..moveTo(path.points[0].dx, path.points[0].dy);
              for (int i = 1; i < path.points.length; i++) {
                polyPath.lineTo(path.points[i].dx, path.points[i].dy);
              }
              canvas.drawPath(polyPath, paint);
            } else {
              canvas.drawLine(start, end, paint);
            }
            break;
          default:
            break;
        }
        continue;
      }

      // paint.strokeWidth = path.strokeWidth;
      for (int i = 0; i < path.points.length - 1; i++) {
        paint.style = PaintingStyle.stroke;
        paint.strokeCap = path.type == BoardTool.eraser
            ? StrokeCap.round
            : StrokeCap.butt;
        paint.isAntiAlias = true;
        if (path.type == BoardTool.highLighter) {
          final pinkGlowCore = pinkLight(0.7); // bright neonColors.pink
          // final pinkBase = pinkLight(0.60); // normal
          // final pinkSoft = pinkLight(0.45); // soft edge
          // final pinkDark = pinkLight(0.30); // shadow

          paint.shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  // HSLColor.fromColor(
                  //   Color(0xffFF00A7),
                  // ).withLightness(.9).toColor(),
                  // HSLColor.fromColor(
                  //   Color(0xffff00a7),
                  // ).withLightness(.90).toColor(),
                  // Colors.limeAccent,
                  // Colors.limeAccent,
                  // Colors.limeAccent,
                  pinkGlowCore, pinkGlowCore,
                  // pinkBase,
                  // pinkSoft,
                  // pinkDark,
                ],
              ).createShader(
                Rect.fromCenter(
                  center: path.points[i],
                  width: 100,
                  height: 100,
                ),
              );
        } else {
          paint.shader = null;
        }
        // paint.blendMode = BlendMode.color;
        paint.strokeWidth = path.strokeWidth;
        canvas.drawLine(path.points[i], path.points[i + 1], paint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final dX = end.dx - start.dx;
    final dY = end.dy - start.dy;
    final angle = math.atan2(dY, dX);
    const arrowSize = 15.0;
    const arrowAngle = math.pi / 6;

    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle - arrowAngle),
      end.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle + arrowAngle),
      end.dy - arrowSize * math.sin(angle + arrowAngle),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
