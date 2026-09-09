import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/bubble_color.dart';
import 'models/grid_position.dart';
import 'models/level_data.dart';
import 'models/game_progress.dart';
import 'painter/particle_system.dart';

enum GameState {
  playing,
  shooting,
  won,
  lost,
  paused,
}

/// Core Game Controller orchestrating physics, grid math, aiming, and game rules
class GameController extends ChangeNotifier {
  final LevelData levelData;
  final ParticleSystem particleSystem = ParticleSystem();
  final math.Random _random = math.Random();

  late List<List<BubbleType?>> grid;
  final int baseCols = 8;
  final int maxRows = 16;

  double bubbleRadius = 20.0;
  double gridStartX = 0.0;
  double boardWidth = 360.0;
  double boardHeight = 600.0;

  // Shooter Station
  late BubbleType currentBubble;
  late BubbleType nextBubble;
  Offset shooterPos = Offset.zero;

  // In-flight projectile
  Offset? projectilePos;
  Offset? projectileVel;
  BubbleType? projectileType;
  final double projectileSpeed = 1600.0;

  // Aiming
  bool isAiming = false;
  double aimAngle = -math.pi / 2; // Pointing straight up by default
  List<Offset> trajectoryPoints = [];

  // Stats & Progress
  int score = 0;
  int remainingShots = 30;
  int comboCount = 0;
  GameState state = GameState.playing;

  // Active Booster
  BubbleType? activeBooster;

  GameController({required this.levelData}) {
    _initLevel();
  }

  void _initLevel() {
    grid = List.generate(
      maxRows,
      (r) {
        final cols = GridPosition.maxColsFor(r, baseCols: baseCols);
        if (r < levelData.initialGrid.length) {
          final initRow = levelData.initialGrid[r];
          return List.generate(cols, (c) => c < initRow.length ? initRow[c] : null);
        }
        return List<BubbleType?>.filled(cols, null);
      },
    );

    remainingShots = levelData.totalShots;
    score = 0;
    comboCount = 0;
    state = GameState.playing;
    particleSystem.clear();

    currentBubble = _getRandomAvailableColor();
    nextBubble = _getRandomAvailableColor();
  }

  void updateLayout(Size size) {
    boardWidth = size.width;
    boardHeight = size.height;

    // Radius computed so baseCols (8) bubbles fit neatly across screen width
    bubbleRadius = (boardWidth / (baseCols + 0.5)) / 2;
    gridStartX = (boardWidth - ((baseCols * 2 * bubbleRadius) + bubbleRadius)) / 2;
    if (gridStartX < 0) gridStartX = 0;

    shooterPos = Offset(boardWidth / 2, boardHeight - (bubbleRadius * 2.8));
    _computeTrajectory();
  }

  BubbleType _getRandomAvailableColor() {
    // Pick from remaining colors on the board if possible
    final activeColors = <BubbleType>{};
    for (final row in grid) {
      for (final b in row) {
        if (b != null && !b.isSpecial) activeColors.add(b);
      }
    }

    final pool = activeColors.isNotEmpty ? activeColors.toList() : levelData.availableColors;
    return pool[_random.nextInt(pool.length)];
  }

  void onTouchStart(Offset touchPos) {
    if (state != GameState.playing) return;
    isAiming = true;
    _updateAim(touchPos);
  }

  void onTouchMove(Offset touchPos) {
    if (!isAiming || state != GameState.playing) return;
    _updateAim(touchPos);
  }

  void onTouchEnd() {
    if (!isAiming || state != GameState.playing) return;
    isAiming = false;
    _shoot();
  }

  void _updateAim(Offset touchPos) {
    final dx = touchPos.dx - shooterPos.dx;
    final dy = touchPos.dy - shooterPos.dy;

    // Only allow aiming upward (between -170 deg and -10 deg)
    double angle = math.atan2(dy, dx);
    const minAngle = -math.pi + 0.18; // ~ -170 deg
    const maxAngle = -0.18;            // ~ -10 deg

    if (angle > 0) {
      // If dragging below shooter, clamp to left/right
      angle = dx < 0 ? minAngle : maxAngle;
    } else {
      angle = angle.clamp(minAngle, maxAngle);
    }

    aimAngle = angle;
    _computeTrajectory();
    notifyListeners();
  }

  void _computeTrajectory() {
    trajectoryPoints.clear();
    if (shooterPos == Offset.zero) return;

    var curPos = shooterPos;
    var vx = math.cos(aimAngle);
    var vy = math.sin(aimAngle);

    trajectoryPoints.add(curPos);

    const stepDist = 8.0;
    const maxSteps = 200;

    final leftBound = bubbleRadius;
    final rightBound = boardWidth - bubbleRadius;

    for (int i = 0; i < maxSteps; i++) {
      curPos += Offset(vx * stepDist, vy * stepDist);

      // Side wall reflection
      if (curPos.dx <= leftBound) {
        curPos = Offset(leftBound, curPos.dy);
        vx = -vx;
        trajectoryPoints.add(curPos);
      } else if (curPos.dx >= rightBound) {
        curPos = Offset(rightBound, curPos.dy);
        vx = -vx;
        trajectoryPoints.add(curPos);
      }

      // Ceiling hit
      if (curPos.dy <= bubbleRadius) {
        trajectoryPoints.add(curPos);
        break;
      }

      // Check potential collision with existing grid bubbles
      if (_checkGridCollision(curPos)) {
        trajectoryPoints.add(curPos);
        break;
      }

      if (i % 2 == 0) {
        trajectoryPoints.add(curPos);
      }
    }
  }

  bool _checkGridCollision(Offset pos) {
    for (int r = 0; r < maxRows; r++) {
      final maxCols = GridPosition.maxColsFor(r, baseCols: baseCols);
      for (int c = 0; c < maxCols; c++) {
        if (grid[r][c] != null) {
          final center = GridPosition.getCenterOffset(r, c, bubbleRadius, gridStartX);
          final distSq = (pos.dx - center.dx) * (pos.dx - center.dx) +
              (pos.dy - center.dy) * (pos.dy - center.dy);
          if (distSq <= (bubbleRadius * 1.85) * (bubbleRadius * 1.85)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _shoot() {
    if (remainingShots <= 0 || state != GameState.playing) return;

    final vx = math.cos(aimAngle) * projectileSpeed;
    final vy = math.sin(aimAngle) * projectileSpeed;

    projectilePos = shooterPos;
    projectileVel = Offset(vx, vy);
    projectileType = activeBooster ?? currentBubble;
    activeBooster = null;

    remainingShots--;
    state = GameState.shooting;

    _hapticTick();
    notifyListeners();
  }

  void swapBubbles() {
    if (state != GameState.playing) return;
    final temp = currentBubble;
    currentBubble = nextBubble;
    nextBubble = temp;
    _hapticTick();
    notifyListeners();
  }

  void activateBooster(BubbleType boosterType) {
    if (state != GameState.playing) return;
    activeBooster = boosterType;
    _hapticTick();
    notifyListeners();
  }

  /// Update loop called per animation frame
  void update(double dt) {
    particleSystem.update(dt, boardHeight);

    if (state == GameState.shooting && projectilePos != null && projectileVel != null) {
      _updateProjectile(dt);
    }

    notifyListeners();
  }

  void _updateProjectile(double dt) {
    var pos = projectilePos!;
    var vel = projectileVel!;

    // Step in smaller sub-steps for smooth high-speed collision detection
    const subSteps = 4;
    final subDt = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      pos += vel * subDt;

      // Left / Right Wall Bounce
      final leftBound = bubbleRadius;
      final rightBound = boardWidth - bubbleRadius;

      if (pos.dx <= leftBound) {
        pos = Offset(leftBound, pos.dy);
        vel = Offset(-vel.dx, vel.dy);
      } else if (pos.dx >= rightBound) {
        pos = Offset(rightBound, pos.dy);
        vel = Offset(-vel.dx, vel.dy);
      }

      // Ceiling Collision
      if (pos.dy <= bubbleRadius) {
        pos = Offset(pos.dx, bubbleRadius);
        _handleBubbleSnap(pos);
        return;
      }

      // Grid Bubble Collision
      if (_checkGridCollision(pos)) {
        _handleBubbleSnap(pos);
        return;
      }
    }

    projectilePos = pos;
    projectileVel = vel;
  }

  void _handleBubbleSnap(Offset hitPos) {
    final snappedCell = GridPosition.findNearestGridCell(
      hitPos,
      bubbleRadius,
      gridStartX,
      baseCols: baseCols,
      maxRows: maxRows,
    );

    final type = projectileType!;
    projectilePos = null;
    projectileVel = null;
    projectileType = null;

    if (snappedCell != null &&
        snappedCell.row < maxRows &&
        grid[snappedCell.row][snappedCell.col] == null) {
      grid[snappedCell.row][snappedCell.col] = type;
      _processPostSnap(snappedCell, type);
    } else {
      // Find fallback closest empty neighbor
      final fallback = _findFallbackEmptyCell(hitPos);
      if (fallback != null) {
        grid[fallback.row][fallback.col] = type;
        _processPostSnap(fallback, type);
      } else {
        // Drop into chamber if completely packed
        _finishTurn();
      }
    }
  }

  GridPosition? _findFallbackEmptyCell(Offset hitPos) {
    GridPosition? bestCell;
    double bestDistSq = double.infinity;

    for (int r = 0; r < maxRows; r++) {
      final maxCols = GridPosition.maxColsFor(r, baseCols: baseCols);
      for (int c = 0; c < maxCols; c++) {
        if (grid[r][c] == null) {
          final center = GridPosition.getCenterOffset(r, c, bubbleRadius, gridStartX);
          final distSq = (hitPos.dx - center.dx) * (hitPos.dx - center.dx) +
              (hitPos.dy - center.dy) * (hitPos.dy - center.dy);
          if (distSq < bestDistSq) {
            bestDistSq = distSq;
            bestCell = GridPosition(r, c);
          }
        }
      }
    }
    return bestCell;
  }

  void _processPostSnap(GridPosition cell, BubbleType type) {
    final center = GridPosition.getCenterOffset(cell.row, cell.col, bubbleRadius, gridStartX);

    if (type == BubbleType.bomb) {
      // Explode all bubbles in 2-cell radius
      _explodeBomb(cell);
    } else if (type == BubbleType.fireball) {
      // Explode entire row
      _explodeRow(cell.row);
    } else {
      // Standard Cluster Match (BFS match 3+)
      final cluster = _findMatchingCluster(cell, type);
      if (cluster.length >= 3) {
        comboCount++;
        final multiplier = comboCount > 1 ? comboCount : 1;
        final clusterScore = cluster.length * 40 * multiplier;
        score += clusterScore;

        for (final pos in cluster) {
          final cPos = GridPosition.getCenterOffset(pos.row, pos.col, bubbleRadius, gridStartX);
          final bType = grid[pos.row][pos.col] ?? type;
          particleSystem.spawnPopBurst(cPos, bType.primaryColor, bubbleRadius);
          grid[pos.row][pos.col] = null;
        }

        final comboLabel = comboCount > 1 ? 'COMBO x$comboCount! +$clusterScore' : '+$clusterScore';
        particleSystem.spawnScore(center, comboLabel, const Color(0xFFFECA57), scale: comboCount > 1 ? 1.3 : 1.0);

        _hapticMedium();

        // Drop any newly disconnected floating bubbles
        _dropFloatingBubbles();
      } else {
        comboCount = 0;
      }
    }

    _finishTurn();
  }

  void _explodeBomb(GridPosition centerCell) {
    final toPop = <GridPosition>{centerCell};
    for (final neighbor in centerCell.getNeighbors(baseCols: baseCols, maxRows: maxRows)) {
      toPop.add(neighbor);
      for (final secondNeighbor in neighbor.getNeighbors(baseCols: baseCols, maxRows: maxRows)) {
        toPop.add(secondNeighbor);
      }
    }

    int count = 0;
    for (final pos in toPop) {
      if (pos.row < maxRows && pos.col < grid[pos.row].length && grid[pos.row][pos.col] != null) {
        final bType = grid[pos.row][pos.col]!;
        final cPos = GridPosition.getCenterOffset(pos.row, pos.col, bubbleRadius, gridStartX);
        particleSystem.spawnPopBurst(cPos, bType.primaryColor, bubbleRadius * 1.5);
        grid[pos.row][pos.col] = null;
        count++;
      }
    }

    final bombScore = count * 60;
    score += bombScore;
    final center = GridPosition.getCenterOffset(centerCell.row, centerCell.col, bubbleRadius, gridStartX);
    particleSystem.spawnScore(center, 'BOOM! +$bombScore', const Color(0xFFFF5252), scale: 1.4);
    _dropFloatingBubbles();
  }

  void _explodeRow(int targetRow) {
    int count = 0;
    if (targetRow >= 0 && targetRow < maxRows) {
      for (int c = 0; c < grid[targetRow].length; c++) {
        if (grid[targetRow][c] != null) {
          final bType = grid[targetRow][c]!;
          final cPos = GridPosition.getCenterOffset(targetRow, c, bubbleRadius, gridStartX);
          particleSystem.spawnPopBurst(cPos, bType.primaryColor, bubbleRadius * 1.3);
          grid[targetRow][c] = null;
          count++;
        }
      }
    }

    final fireScore = count * 50;
    score += fireScore;
    _dropFloatingBubbles();
  }

  List<GridPosition> _findMatchingCluster(GridPosition start, BubbleType type) {
    final visited = <GridPosition>{};
    final cluster = <GridPosition>[];
    final queue = <GridPosition>[start];
    visited.add(start);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      cluster.add(current);

      for (final neighbor in current.getNeighbors(baseCols: baseCols, maxRows: maxRows)) {
        if (!visited.contains(neighbor)) {
          final neighborType = grid[neighbor.row][neighbor.col];
          if (neighborType != null &&
              (neighborType == type || neighborType == BubbleType.rainbow || type == BubbleType.rainbow)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    }

    return cluster;
  }

  void _dropFloatingBubbles() {
    // 1. Mark all bubbles connected to the top ceiling (row 0)
    final connected = <GridPosition>{};
    final queue = <GridPosition>[];

    // Row 0 anchor bubbles
    for (int c = 0; c < grid[0].length; c++) {
      if (grid[0][c] != null) {
        final pos = GridPosition(0, c);
        connected.add(pos);
        queue.add(pos);
      }
    }

    // Traverse connected network
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final neighbor in current.getNeighbors(baseCols: baseCols, maxRows: maxRows)) {
        if (!connected.contains(neighbor) && grid[neighbor.row][neighbor.col] != null) {
          connected.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    // 2. Any bubble not connected falls down
    int droppedCount = 0;
    for (int r = 0; r < maxRows; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        final bType = grid[r][c];
        if (bType != null && !connected.contains(GridPosition(r, c))) {
          final center = GridPosition.getCenterOffset(r, c, bubbleRadius, gridStartX);
          particleSystem.spawnFallingBubble(center, bType, bubbleRadius);
          grid[r][c] = null;
          droppedCount++;
        }
      }
    }

    if (droppedCount > 0) {
      final dropScore = droppedCount * 100;
      score += dropScore;
      final dropMsg = 'DROP! +$dropScore';
      particleSystem.spawnScore(
        Offset(boardWidth / 2, boardHeight * 0.4),
        dropMsg,
        const Color(0xFF00CEC9),
        scale: 1.3,
      );
    }
  }

  void _finishTurn() {
    // Advance queue
    currentBubble = nextBubble;
    nextBubble = _getRandomAvailableColor();

    // Check Win Condition: Board has no bubbles left
    bool boardCleared = true;
    int lowestRowWithBubble = -1;

    for (int r = 0; r < maxRows; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (grid[r][c] != null) {
          boardCleared = false;
          if (r > lowestRowWithBubble) lowestRowWithBubble = r;
        }
      }
    }

    if (boardCleared) {
      state = GameState.won;
      // Bonus score for remaining shots
      score += remainingShots * 250;
      _saveProgress();
    } else if (remainingShots <= 0 || lowestRowWithBubble >= maxRows - 3) {
      state = GameState.lost;
    } else {
      state = GameState.playing;
    }

    _computeTrajectory();
    notifyListeners();
  }

  int calculateStars() {
    if (state != GameState.won) return 0;
    if (score >= levelData.targetScore3Star) return 3;
    if (score >= levelData.targetScore2Star) return 2;
    return 1;
  }

  void _saveProgress() {
    final stars = calculateStars();
    GameProgress().saveLevelResult(levelData.levelNumber, score, stars);
  }

  void _hapticTick() {
    if (GameProgress().hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _hapticMedium() {
    if (GameProgress().hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
}
