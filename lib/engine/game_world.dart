import 'dart:math' as math;
import '../models/vector2.dart';
import '../models/trench_tile.dart';
import '../models/submarine.dart';
import '../models/monster.dart';
import '../models/sonar_wave.dart';
import '../models/particle.dart';

class GameWorld {
  static const int gridWidth = 44;
  static const int gridHeight = 44;
  static const double tileSize = 32.0;

  double get worldWidth => gridWidth * tileSize;
  double get worldHeight => gridHeight * tileSize;

  late List<List<TrenchTile>> grid;
  late Submarine submarine;
  late Monster monster;
  final List<SonarWave> waves = [];
  final List<Particle> particles = [];

  Vector2 submarineStartPos = const Vector2(160, 160);
  Vector2 monsterSpawnPos = const Vector2(800, 800);
  Vector2 exitDockPos = const Vector2(1200, 1200);

  int totalRelics = 3;
  int collectedRelics = 0;
  bool isVictory = false;

  int currentSeed = 42;

  GameWorld({int? seed}) {
    initWorld(seed);
  }

  void initWorld([int? seed]) {
    currentSeed = seed ?? (math.Random().nextInt(900000) + 1000);

    // 1. Initialize grid with empty tiles
    grid = List.generate(
      gridWidth,
      (x) => List.generate(
        gridHeight,
        (y) => TrenchTile(gridX: x, gridY: y, type: TileType.empty),
      ),
    );

    // 2. Build trench cave system with procedural seed
    _generateTrenchMap();

    // 3. Spawn submarine
    submarine = Submarine(
      position: submarineStartPos,
      totalRelics: totalRelics,
    );

    // 4. Spawn monster
    monster = Monster(position: monsterSpawnPos);

    // 5. Reset waves & particles
    waves.clear();
    particles.clear();
    collectedRelics = 0;
    isVictory = false;

    // Seed initial marine snow
    final rand = math.Random(currentSeed);
    for (int i = 0; i < 50; i++) {
      particles.add(
        Particle.marineSnow(
          Vector2(rand.nextDouble() * worldWidth, rand.nextDouble() * worldHeight),
        ),
      );
    }
  }

  void _generateTrenchMap() {
    final rand = math.Random(currentSeed);
    final offsetX = rand.nextDouble() * 20.0;
    final offsetY = rand.nextDouble() * 20.0;

    // Outer boundary walls
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        if (x == 0 || y == 0 || x == gridWidth - 1 || y == gridHeight - 1) {
          grid[x][y].type = TileType.wall;
        }
      }
    }

    // Procedural rock clusters & winding cavern walls
    for (int x = 2; x < gridWidth - 2; x++) {
      for (int y = 2; y < gridHeight - 2; y++) {
        // Safe starting clearing around (5, 5)
        if (x >= 3 && x <= 8 && y >= 3 && y <= 8) continue;
        // Monster lair clearing around (28, 28)
        if (x >= 25 && x <= 31 && y >= 25 && y <= 31) continue;
        // Exit dock clearing around (38, 38)
        if (x >= 35 && x <= 41 && y >= 35 && y <= 41) continue;

        // Cellular / noise wall distribution with seed offset
        final noise = math.sin((x + offsetX) * 0.38) * math.cos((y + offsetY) * 0.38) +
            math.sin((x - offsetY) * 0.16 + (y + offsetX) * 0.22) * 0.45 +
            (rand.nextDouble() - 0.5) * 0.35;

        if (noise > 0.42) {
          grid[x][y].type = (rand.nextDouble() < 0.28)
              ? TileType.jaggedRock
              : TileType.wall;
        }
      }
    }

    // Candidate relic alcoves across different trench sectors
    final candidateAlcoves = [
      {'cx': 36, 'cy': 8, 'edx': -1, 'edy': 0},
      {'cx': 8, 'cy': 36, 'edx': 0, 'edy': -1},
      {'cx': 24, 'cy': 38, 'edx': 1, 'edy': 0},
      {'cx': 36, 'cy': 24, 'edx': -1, 'edy': 0},
      {'cx': 14, 'cy': 22, 'edx': 0, 'edy': 1},
      {'cx': 26, 'cy': 12, 'edx': 0, 'edy': 1},
    ]..shuffle(rand);

    // Build 3 distinct enclosed alcoves for relics
    for (int i = 0; i < 3; i++) {
      final alcove = candidateAlcoves[i];
      final cx = alcove['cx'] as int;
      final cy = alcove['cy'] as int;
      final edx = alcove['edx'] as int;
      final edy = alcove['edy'] as int;

      _buildEnclosedAlcove(cx, cy, entryDx: edx, entryDy: edy);
      grid[cx][cy].type = TileType.relic;
    }

    // Place hydrothermal vents for battery recharging
    final ventPool = [
      const math.Point(14, 16),
      const math.Point(28, 14),
      const math.Point(18, 32),
      const math.Point(32, 34),
    ]..shuffle(rand);

    for (int i = 0; i < 3; i++) {
      final pt = ventPool[i];
      _clearZone(pt.x, pt.y, radius: 1);
      grid[pt.x][pt.y].type = TileType.hydrothermalVent;
    }

    // Place extraction subsea dock at far corner
    const exitX = 38;
    const exitY = 38;
    _clearZone(exitX, exitY, radius: 2);
    grid[exitX][exitY].type = TileType.exitDock;
    exitDockPos = Vector2(exitX * tileSize + tileSize / 2, exitY * tileSize + tileSize / 2);

    // Setup coordinates: submarine starts top-left (5, 5), Monster spawns in far abyss (28, 28)
    submarineStartPos = const Vector2(5 * tileSize, 5 * tileSize);
    monsterSpawnPos = const Vector2(28 * tileSize, 28 * tileSize);
  }

  void _buildEnclosedAlcove(int cx, int cy, {required int entryDx, required int entryDy}) {
    // Clear inner chamber
    _clearZone(cx, cy, radius: 1);

    // Enclose with wall/jagged rock perimeter
    for (int dx = -2; dx <= 2; dx++) {
      for (int dy = -2; dy <= 2; dy++) {
        if (dx.abs() == 2 || dy.abs() == 2) {
          final x = cx + dx;
          final y = cy + dy;
          if (x >= 1 && x < gridWidth - 1 && y >= 1 && y < gridHeight - 1) {
            // Keep designated entry passage open
            if ((dx == entryDx * 2 && dy == entryDy * 2) ||
                (dx == entryDx && dy == entryDy)) {
              grid[x][y].type = TileType.empty;
            } else {
              grid[x][y].type = (dx * dy % 2 == 0) ? TileType.wall : TileType.jaggedRock;
            }
          }
        }
      }
    }
  }

  void _clearZone(int cx, int cy, {int radius = 1}) {
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final x = cx + dx;
        final y = cy + dy;
        if (x >= 1 && x < gridWidth - 1 && y >= 1 && y < gridHeight - 1) {
          grid[x][y].type = TileType.empty;
        }
      }
    }
  }

  TrenchTile? getTileAt(Vector2 pos) {
    final gx = (pos.x / tileSize).floor();
    final gy = (pos.y / tileSize).floor();
    if (gx >= 0 && gx < gridWidth && gy >= 0 && gy < gridHeight) {
      return grid[gx][gy];
    }
    return null;
  }

  Vector2 getTileCenter(int gx, int gy) {
    return Vector2((gx + 0.5) * tileSize, (gy + 0.5) * tileSize);
  }

  void spawnParticles(Particle p) {
    if (particles.length < 250) {
      particles.add(p);
    }
  }

  void updateParticles(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].isDead) {
        particles.removeAt(i);
      }
    }

    // Spawn ambient marine snow around submarine viewport
    final rand = math.Random();
    if (particles.length < 150 && rand.nextDouble() < 0.4) {
      final offset = Vector2(
        (rand.nextDouble() - 0.5) * 600.0,
        (rand.nextDouble() - 0.5) * 600.0,
      );
      spawnParticles(Particle.marineSnow(submarine.position + offset));
    }
  }
}
