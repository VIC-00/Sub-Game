import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_sea_echo/models/vector2.dart';
import 'package:deep_sea_echo/models/submarine.dart';
import 'package:deep_sea_echo/models/trench_tile.dart';
import 'package:deep_sea_echo/models/sonar_wave.dart';
import 'package:deep_sea_echo/models/monster.dart';
import 'package:deep_sea_echo/models/upgrade_state.dart';
import 'package:deep_sea_echo/engine/game_world.dart';
import 'package:deep_sea_echo/engine/collision_system.dart';
import 'package:deep_sea_echo/engine/game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vector2 Mathematics', () {
    test('vector arithmetic and distance calculations', () {
      const v1 = Vector2(3, 4);
      expect(v1.length, closeTo(5.0, 0.0001));

      final v2 = Vector2(1, 1);
      final sum = v1 + v2;
      expect(sum.x, 4.0);
      expect(sum.y, 5.0);

      final norm = v1.normalized();
      expect(norm.length, closeTo(1.0, 0.0001));
      expect(v1.distanceTo(const Vector2(6, 8)), closeTo(5.0, 0.0001));
    });

    test('vector rotation', () {
      const v = Vector2(1, 0);
      final rotated = v.rotate(math.pi / 2);
      expect(rotated.x, closeTo(0.0, 0.0001));
      expect(rotated.y, closeTo(1.0, 0.0001));
    });
  });

  group('Trench Phosphor & Tile Mechanics', () {
    test('tile excites and decays back into darkness', () {
      final tile = TrenchTile(gridX: 5, gridY: 5, type: TileType.wall);
      expect(tile.luminance, 0.0);
      expect(tile.discovered, false);

      tile.excite(0.9);
      expect(tile.luminance, closeTo(0.9, 0.001));
      expect(tile.discovered, true);

      // Advance time by 2 seconds
      tile.update(2.0, decayRate: 0.28);
      expect(tile.luminance, closeTo(0.9 - (2.0 * 0.28), 0.001));

      // Advance by another 4 seconds -> should be 0.0
      tile.update(4.0, decayRate: 0.28);
      expect(tile.luminance, 0.0);
    });
  });

  group('Sonar Wave Propagation & Monster Perception', () {
    test('loud ping has higher noise level and larger radius than soft ping', () {
      final soft = SonarWave.soft(origin: const Vector2(100, 100), id: 's1');
      final loud = SonarWave.loud(origin: const Vector2(100, 100), id: 'l1');

      expect(loud.noiseLevel, greaterThan(soft.noiseLevel));
      expect(loud.maxRadius, greaterThan(soft.maxRadius));
      expect(loud.expansionSpeed, greaterThan(soft.expansionSpeed));
    });

    test('monster hears loud ping and investigates epicenter', () {
      final monster = Monster(position: const Vector2(500, 500));
      expect(monster.state, MonsterState.dormant);

      // Acoustic noise emitted 400 units away
      const pingEpicenter = Vector2(200, 200);
      monster.hearSound(pingEpicenter, 1.0); // Loud ping

      expect(monster.state, MonsterState.investigating);
      expect(monster.targetNoisePosition, equals(pingEpicenter));
    });

    test('sonar wave hit reveals monster visibility', () {
      final monster = Monster(position: const Vector2(300, 300));
      expect(monster.isVisible, false);

      monster.pingHit(1.0);
      expect(monster.isVisible, true);
      expect(monster.revealedTimer, greaterThan(1.5));
    });
  });

  group('Collision & Resource Systems', () {
    test('submarine collects relics, gains decoys and energy', () {
      final world = GameWorld();
      final collisionSystem = CollisionSystem();

      final initialDecoys = world.submarine.decoysRemaining;
      world.submarine.battery = 40.0;

      // Place a relic right at submarine position
      final subPos = world.submarine.position;
      final tile = world.getTileAt(subPos)!;
      tile.type = TileType.relic;
      tile.relicCollected = false;

      expect(world.submarine.collectedRelics, 0);
      collisionSystem.update(world, 0.016);
      expect(world.submarine.collectedRelics, 1);
      expect(tile.relicCollected, true);
      expect(world.submarine.decoysRemaining, initialDecoys + 1);
      expect(world.submarine.battery, greaterThan(40.0));
    });

    test('passive reactor recharge when stationary and emergency drift', () {
      final sub = Submarine(position: const Vector2(100, 100));
      sub.battery = 10.0;
      sub.isThrusting = false;

      // Rest for 2 seconds -> should recharge passively
      sub.update(2.0);
      expect(sub.battery, greaterThan(12.0));

      // Deplete battery to 0
      sub.battery = 0.0;
      expect(sub.isEmergencyDrift, true);

      // In emergency drift, sub can still thrust with reduced power
      sub.thrust(const Vector2(1, 0), 0.5);
      expect(sub.velocity.x, greaterThan(0.0));
    });

    test('docking at extraction dock with all relics triggers victory', () {
      final world = GameWorld();
      final collisionSystem = CollisionSystem();

      world.submarine.collectedRelics = world.submarine.totalRelics;
      world.submarine.position = world.exitDockPos;

      expect(world.isVictory, false);
      collisionSystem.update(world, 0.016);
      expect(world.isVictory, true);
    });

    test('hydrothermal vent recharges battery', () {
      final world = GameWorld();
      final collisionSystem = CollisionSystem();

      world.submarine.battery = 30.0;
      final subPos = world.submarine.position;
      final tile = world.getTileAt(subPos)!;
      tile.type = TileType.hydrothermalVent;

      collisionSystem.update(world, 1.0);
      expect(world.submarine.battery, greaterThan(30.0));
    });
  });

  group('Progression & UpgradeState', () {
    test('upgrading hull and dampener updates stats and consumes scrap', () {
      final up = UpgradeState();
      up.totalScrap = 200;

      expect(up.maxHull, 100.0);
      expect(up.hullLevel, 0);

      final success = up.upgradeHull();
      expect(success, true);
      expect(up.hullLevel, 1);
      expect(up.maxHull, 120.0);
      expect(up.totalScrap, 150); // 200 - 50

      final dampSuccess = up.upgradeDampener();
      expect(dampSuccess, true);
      expect(up.dampenerLevel, 1);
      expect(up.noiseMultiplier, closeTo(0.88, 0.001));
      expect(up.totalScrap, 90); // 150 - 60
    });
  });

  group('Map Variety & Procedural Generation', () {
    test('different seeds produce different trench configurations', () {
      final world1 = GameWorld(seed: 1111);
      final world2 = GameWorld(seed: 9999);

      // Compare tiles across the map: at least some tiles should differ
      int differences = 0;
      for (int x = 2; x < GameWorld.gridWidth - 2; x++) {
        for (int y = 2; y < GameWorld.gridHeight - 2; y++) {
          if (world1.grid[x][y].type != world2.grid[x][y].type) {
            differences++;
          }
        }
      }
      expect(differences, greaterThan(20));
    });
  });

  group('GameController State Machine', () {
    test('charging sonar updates charge ratio and fires wave', () {
      final controller = GameController();
      expect(controller.isChargingSonar, false);

      controller.startSonarCharge();
      expect(controller.isChargingSonar, true);

      controller.updateSonarCharge(1.4); // Full charge
      expect(controller.sonarChargeRatio, closeTo(1.0, 0.001));

      controller.releaseSonarCharge();
      expect(controller.isChargingSonar, false);
      expect(controller.sonarChargeRatio, 0.0);
      expect(controller.world.waves.isNotEmpty, true);
      expect(controller.pingsCount, 1);
    });
  });
}
