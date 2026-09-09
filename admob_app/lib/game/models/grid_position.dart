import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Represents a cell in the hexagonal bubble shooter grid
class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridPosition(row: $row, col: $col)';

  /// Returns whether this row has offset (odd rows are offset)
  bool get isOffset => row.isOdd;

  /// Max columns for a given row (8 for even, 7 for odd)
  static int maxColsFor(int row, {int baseCols = 8}) {
    return row.isEven ? baseCols : baseCols - 1;
  }

  /// Calculates world pixel center (x, y) for a grid coordinate
  static Offset getCenterOffset(int row, int col, double radius, double gridStartX) {
    final rowHeight = radius * math.sqrt(3);
    final isOddRow = row.isOdd;
    final x = gridStartX + (col * 2 * radius) + radius + (isOddRow ? radius : 0.0);
    final y = (row * rowHeight) + radius;
    return Offset(x, y);
  }

  /// Finds the closest valid grid cell for a given world position (x, y)
  static GridPosition? findNearestGridCell(
    Offset position,
    double radius,
    double gridStartX, {
    int baseCols = 8,
    int maxRows = 20,
  }) {
    final rowHeight = radius * math.sqrt(3);
    final approxRow = ((position.dy - radius) / rowHeight).round().clamp(0, maxRows - 1);

    int bestCol = 0;
    double bestDistSq = double.infinity;
    final maxCols = maxColsFor(approxRow, baseCols: baseCols);

    for (int c = 0; c < maxCols; c++) {
      final center = getCenterOffset(approxRow, c, radius, gridStartX);
      final distSq = (position.dx - center.dx) * (position.dx - center.dx) +
          (position.dy - center.dy) * (position.dy - center.dy);
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        bestCol = c;
      }
    }

    // Check if within acceptable snapping distance (1.4 * radius)
    if (bestDistSq <= (radius * 1.5) * (radius * 1.5)) {
      return GridPosition(approxRow, bestCol);
    }
    return null;
  }

  /// Gets all valid 6 hexagonal neighbors for this grid position
  List<GridPosition> getNeighbors({int baseCols = 8, int maxRows = 20}) {
    final neighbors = <GridPosition>[];
    final isOdd = row.isOdd;

    final potentialDeltas = isOdd
        ? const [
            [-1, 0],  // Top-Left
            [-1, 1],  // Top-Right
            [0, -1],  // Left
            [0, 1],   // Right
            [1, 0],   // Bottom-Left
            [1, 1],   // Bottom-Right
          ]
        : const [
            [-1, -1], // Top-Left
            [-1, 0],  // Top-Right
            [0, -1],  // Left
            [0, 1],   // Right
            [1, -1],  // Bottom-Left
            [1, 0],   // Bottom-Right
          ];

    for (final delta in potentialDeltas) {
      final nRow = row + delta[0];
      final nCol = col + delta[1];

      if (nRow >= 0 && nRow < maxRows) {
        final maxCols = maxColsFor(nRow, baseCols: baseCols);
        if (nCol >= 0 && nCol < maxCols) {
          neighbors.add(GridPosition(nRow, nCol));
        }
      }
    }

    return neighbors;
  }
}
