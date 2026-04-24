import 'dart:ui';

import 'package:white_board/src/home/board/board.dart';

enum ShapeType { none, circle, arrow, line, rectangle, square, polygon }

class DrawingPath {
  final Color color;
  final List<Offset> points;
  final double strokeWidth;
  final BoardTool type;
  final ShapeType shapeType;
  final bool? isFilled;

  DrawingPath({
    required this.color,
    required this.points,
    required this.strokeWidth,
    required this.type,
    this.shapeType = ShapeType.none,
    this.isFilled = false,
  });
}
