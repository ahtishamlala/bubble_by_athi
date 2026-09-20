import 'dart:math';
import 'package:flutter/material.dart';

class BlockShape {
  final List<List<int>> matrix;
  final Color color;
  final String name;

  const BlockShape({
    required this.matrix,
    required this.color,
    required this.name,
  });

  int get rows => matrix.length;
  int get cols => matrix[0].length;

  static final List<BlockShape> shapes = [
    // 1x1 Dot
    const BlockShape(
      matrix: [
        [1],
      ],
      color: Color(0xFFFFD700),
      name: 'Dot',
    ),
    // 1x2 Line
    const BlockShape(
      matrix: [
        [1, 1],
      ],
      color: Color(0xFF00F2FE),
      name: 'Line2H',
    ),
    // 2x1 Line
    const BlockShape(
      matrix: [
        [1],
        [1],
      ],
      color: Color(0xFF00F2FE),
      name: 'Line2V',
    ),
    // 1x3 Line
    const BlockShape(
      matrix: [
        [1, 1, 1],
      ],
      color: Color(0xFF00E676),
      name: 'Line3H',
    ),
    // 3x1 Line
    const BlockShape(
      matrix: [
        [1],
        [1],
        [1],
      ],
      color: Color(0xFF00E676),
      name: 'Line3V',
    ),
    // 2x2 Square
    const BlockShape(
      matrix: [
        [1, 1],
        [1, 1],
      ],
      color: Color(0xFFFF2A85),
      name: 'Square2x2',
    ),
    // L-Shape
    const BlockShape(
      matrix: [
        [1, 0],
        [1, 0],
        [1, 1],
      ],
      color: Color(0xFF9B51E0),
      name: 'L-Shape',
    ),
    // Reversed L
    const BlockShape(
      matrix: [
        [0, 1],
        [0, 1],
        [1, 1],
      ],
      color: Color(0xFFFF7A00),
      name: 'Rev-L',
    ),
    // T-Shape
    const BlockShape(
      matrix: [
        [1, 1, 1],
        [0, 1, 0],
      ],
      color: Color(0xFFFF3366),
      name: 'T-Shape',
    ),
    // Small Corner
    const BlockShape(
      matrix: [
        [1, 1],
        [1, 0],
      ],
      color: Color(0xFF4FACFE),
      name: 'Corner',
    ),
  ];

  static BlockShape randomShape() {
    final rand = Random();
    return shapes[rand.nextInt(shapes.length)];
  }
}
