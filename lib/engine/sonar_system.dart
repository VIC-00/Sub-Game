import 'dart:math' as math;
import '../models/vector2.dart';
import '../models/sonar_wave.dart';
import '../models/trench_tile.dart';
import 'game_world.dart';

class SonarSystem {
  int _waveCounter = 0;

  SonarWave? emitPing(GameWorld world, PingType type) {
    final sub = world.submarine;
    if (sub.isDead) return null;

    double batteryCost = 0.0;
    switch (type) {
      case PingType.soft:
        batteryCost = 4.0;
        break;
      case PingType.medium:
        batteryCost = 10.0;
        break;
      case PingType.loud:
        batteryCost = 22.0;
        break;
      case PingType.decoy:
        if (sub.decoysRemaining <= 0) return null;
        sub.decoysRemaining--;
        batteryCost = 5.0;
        break;
    }

    if (!sub.consumeBattery(batteryCost)) {
      return null; // Not enough battery
    }

    final waveId = 'wave_${++_waveCounter}';
    late SonarWave wave;

    if (type == PingType.decoy) {
      // Launch decoy 150px ahead of sub heading
      final decoyPos = sub.position + Vector2.fromAngle(sub.heading, 150.0);
      wave = SonarWave.decoy(origin: decoyPos, id: waveId);
    } else {
      switch (type) {
        case PingType.soft:
          wave = SonarWave.soft(origin: sub.position, id: waveId);
          break;
        case PingType.medium:
          wave = SonarWave.medium(origin: sub.position, id: waveId);
          break;
        case PingType.loud:
          wave = SonarWave.loud(origin: sub.position, id: waveId);
          break;
        default:
          wave = SonarWave.soft(origin: sub.position, id: waveId);
      }
    }

    world.waves.add(wave);

    // Alert monster of acoustic pulse
    world.monster.hearSound(wave.origin, wave.noiseLevel);

    return wave;
  }

  void update(GameWorld world, double dt) {
    // 1. Update all grid tiles (phosphor decay)
    for (int x = 0; x < GameWorld.gridWidth; x++) {
      for (int y = 0; y < GameWorld.gridHeight; y++) {
        world.grid[x][y].update(dt);
      }
    }

    // 2. Update active sonar waves and excite intersected tiles
    for (int i = world.waves.length - 1; i >= 0; i--) {
      final wave = world.waves[i];
      final prevRadius = wave.currentRadius;
      wave.update(dt);
      final currentRadius = wave.currentRadius;

      if (wave.isFinished) {
        world.waves.removeAt(i);
        continue;
      }

      // Check which tiles intersect the annular band [prevRadius, currentRadius + 8.0]
      _exciteIntersectedTiles(world, wave, prevRadius, currentRadius + 8.0);

      // Excite marine particles caught in the expanding wavefront
      for (final p in world.particles) {
        final dist = wave.origin.distanceTo(p.position);
        if (dist >= prevRadius && dist <= currentRadius + 12.0) {
          p.excite(wave.intensity * 1.2);
        }
      }

      // Check if wavefront reached monster
      final distToMonster = wave.origin.distanceTo(world.monster.position);
      if (distToMonster >= prevRadius && distToMonster <= currentRadius + 16.0) {
        world.monster.pingHit(wave.intensity);
      }
    }
  }

  void _exciteIntersectedTiles(
    GameWorld world,
    SonarWave wave,
    double innerR,
    double outerR,
  ) {
    final origin = wave.origin;
    final ts = GameWorld.tileSize;

    // Bounding grid box for the current ring
    final minGx = math.max(0, ((origin.x - outerR) / ts).floor());
    final maxGx = math.min(GameWorld.gridWidth - 1, ((origin.x + outerR) / ts).ceil());
    final minGy = math.max(0, ((origin.y - outerR) / ts).floor());
    final maxGy = math.min(GameWorld.gridHeight - 1, ((origin.y + outerR) / ts).ceil());

    final innerRSq = innerR * innerR;
    final outerRSq = outerR * outerR;

    for (int x = minGx; x <= maxGx; x++) {
      for (int y = minGy; y <= maxGy; y++) {
        final tile = world.grid[x][y];
        // Only solid or interactive tiles reflect sonar echo
        if (tile.type == TileType.empty) continue;

        final center = world.getTileCenter(x, y);
        final distSq = origin.distanceSquaredTo(center);

        if (distSq >= innerRSq && distSq <= outerRSq) {
          final intensity = wave.intensity;
          tile.excite(intensity);
        }
      }
    }
  }
}

