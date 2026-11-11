import 'dart:math' as math;
import '../models/vector2.dart';
import '../models/trench_tile.dart';
import '../models/particle.dart';
import 'game_world.dart';

class CollisionSystem {
  void update(GameWorld world, double dt) {
    final sub = world.submarine;
    if (sub.isDead) return;

    final subRadius = sub.radius;
    final subPos = sub.position;
    final ts = GameWorld.tileSize;

    // Check tiles in 3x3 vicinity
    final minGx = math.max(0, ((subPos.x - subRadius) / ts).floor());
    final maxGx = math.min(GameWorld.gridWidth - 1, ((subPos.x + subRadius) / ts).floor());
    final minGy = math.max(0, ((subPos.y - subRadius) / ts).floor());
    final maxGy = math.min(GameWorld.gridHeight - 1, ((subPos.y + subRadius) / ts).floor());

    for (int gx = minGx; gx <= maxGx; gx++) {
      for (int gy = minGy; gy <= maxGy; gy++) {
        final tile = world.grid[gx][gy];

        // 1. Relic Collection (Salvage Data Core, Auxiliary Battery Cell & Decoy)
        if (tile.isRelic) {
          final tileCenter = world.getTileCenter(gx, gy);
          if (subPos.distanceTo(tileCenter) < subRadius + ts * 0.45) {
            tile.relicCollected = true;
            sub.collectedRelics++;
            sub.decoysRemaining++; // Salvage extra decoy!
            sub.rechargeBattery(35.0); // Salvage energy cells!
            sub.repair(15.0); // Salvage repair parts!

            // Burst celebration sparks
            for (int p = 0; p < 18; p++) {
              world.spawnParticles(Particle.spark(tileCenter));
            }
          }
        }

        // 2. Hydrothermal Vent Battery Recharge
        if (tile.isVent) {
          final tileCenter = world.getTileCenter(gx, gy);
          if (subPos.distanceTo(tileCenter) < ts * 1.5) {
            sub.rechargeBattery(dt * 22.0); // Rapid geothermal recharge
            world.spawnParticles(Particle.ventParticle(tileCenter));
          }
        }

        // 3. Victory Check at Exit Dock
        if (sub.allRelicsCollected) {
          final distToDock = subPos.distanceTo(world.exitDockPos);
          if (distToDock < 48.0) {
            world.isVictory = true;
          }
        }

        // 4. Solid Obstacle Collision (Rock / Wall / Jagged Rock)
        if (tile.isSolid) {
          _resolveCircleAABBCollision(world, sub, gx, gy, tile);
        }
      }
    }
  }

  void _resolveCircleAABBCollision(
    GameWorld world,
    dynamic sub,
    int gx,
    int gy,
    TrenchTile tile,
  ) {
    final ts = GameWorld.tileSize;
    final tileLeft = gx * ts;
    final tileTop = gy * ts;
    final tileRight = tileLeft + ts;
    final tileBottom = tileTop + ts;

    // Closest point on AABB to circle center
    final closestX = sub.position.x.clamp(tileLeft, tileRight);
    final closestY = sub.position.y.clamp(tileTop, tileBottom);

    final closestPt = Vector2(closestX, closestY);
    final diff = sub.position - closestPt;
    final dist = diff.length;

    if (dist < sub.radius && dist > 0.0001) {
      // Overlap detected!
      final penetration = sub.radius - dist;
      final normal = diff / dist;

      // Push out of wall
      sub.position += normal * penetration;

      // Impact velocity normal component
      final normalVelocity = sub.velocity.dot(normal);
      if (normalVelocity < 0) {
        final impactSpeed = -normalVelocity;
        // Bounce
        sub.velocity = sub.velocity - normal * (normalVelocity * 1.4);

        // Apply crash damage if fast collision
        if (impactSpeed > 45.0) {
          double damage = impactSpeed * 0.12;
          if (tile.isHazard) {
            damage *= 2.2; // Jagged rocks are much more lethal
          }
          sub.takeDamage(damage);

          // Spawn collision sparks and bubbles
          for (int i = 0; i < 4; i++) {
            world.spawnParticles(Particle.spark(closestPt));
          }
        }
      }
    }
  }
}

