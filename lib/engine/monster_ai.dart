import 'dart:math' as math;
import 'dart:ui';
import '../models/particle.dart';
import '../models/vector2.dart';
import 'game_world.dart';

class MonsterAI {
  double _trailTimer = 0.0;

  void update(GameWorld world, double dt) {
    final monster = world.monster;
    final sub = world.submarine;

    // 1. Advance monster brain and movement
    monster.update(dt, sub.position, sub.acousticNoise);

    // 2. Spawn eerie water ripples / disturbance particles along monster spine
    _trailTimer += dt;
    if (_trailTimer > 0.12) {
      _trailTimer = 0.0;
      if (monster.velocity.lengthSquared > 100.0) {
        final rand = math.Random();
        world.spawnParticles(
          Particle(
            position: monster.position +
                Vector2((rand.nextDouble() - 0.5) * 16.0, (rand.nextDouble() - 0.5) * 16.0),
            velocity: -monster.velocity * 0.1,
            maxLife: 0.6 + rand.nextDouble() * 0.4,
            size: 2.5 + rand.nextDouble() * 2.0,
            color: const Color(0x66FF1744), // Bioluminescent warning red
            type: ParticleType.bubble,
          ),
        );
      }
    }

    // 3. Check monster attack on submarine
    if (!sub.isDead) {
      final distToHead = monster.position.distanceTo(sub.position);
      if (distToHead < 28.0) {
        // Direct predator attack!
        sub.takeDamage(dt * 35.0); // Rapid hull tear
        // Spawn sparks & cavitation
        world.spawnParticles(Particle.spark(sub.position));
      } else {
        // Also check middle segments
        for (int i = 1; i < 4; i++) {
          if (monster.segments[i].position.distanceTo(sub.position) < 22.0) {
            sub.takeDamage(dt * 20.0);
            break;
          }
        }
      }
    }
  }
}
