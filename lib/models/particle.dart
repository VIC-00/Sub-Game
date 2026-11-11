import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'vector2.dart';

enum ParticleType {
  marineSnow,
  bubble,
  ventSmoke,
  spark,
  echoRipple,
}

class Particle {
  Vector2 position;
  Vector2 velocity;
  double life; // Remaining lifetime in seconds
  final double maxLife;
  final double size;
  final Color color;
  final ParticleType type;
  double luminescence; // Excitation when hit by sonar wave

  Particle({
    required this.position,
    required this.velocity,
    required this.maxLife,
    required this.size,
    required this.color,
    required this.type,
    this.luminescence = 0.0,
  }) : life = maxLife;

  bool get isDead => life <= 0.0;
  double get progress => (life / maxLife).clamp(0.0, 1.0);

  void excite(double amount) {
    luminescence = (luminescence + amount).clamp(0.0, 1.0);
  }

  void update(double dt) {
    life -= dt;
    position += velocity * dt;
    if (luminescence > 0) {
      luminescence = math.max(0.0, luminescence - dt * 0.8);
    }

    if (type == ParticleType.bubble || type == ParticleType.ventSmoke) {
      // Bubbles rise slightly and wobble
      velocity = Vector2(
        velocity.x + (math.Random().nextDouble() - 0.5) * 15.0 * dt,
        velocity.y - 12.0 * dt,
      );
    } else if (type == ParticleType.marineSnow) {
      // Marine snow drifts gently with ocean currents
      velocity = velocity * (1.0 - 0.2 * dt);
    }
  }

  static Particle marineSnow(Vector2 pos) {
    final rand = math.Random();
    return Particle(
      position: pos,
      velocity: Vector2(
        (rand.nextDouble() - 0.5) * 6.0,
        rand.nextDouble() * 4.0 + 1.0,
      ),
      maxLife: 4.0 + rand.nextDouble() * 6.0,
      size: 1.0 + rand.nextDouble() * 1.5,
      color: Colors.white.withValues(alpha: 0.35),
      type: ParticleType.marineSnow,
    );
  }

  static Particle cavitationBubble(Vector2 pos, Vector2 subHeading) {
    final rand = math.Random();
    final backAngle = subHeading.angle + math.pi + (rand.nextDouble() - 0.5) * 0.5;
    return Particle(
      position: pos,
      velocity: Vector2.fromAngle(backAngle, 20.0 + rand.nextDouble() * 30.0),
      maxLife: 0.8 + rand.nextDouble() * 0.6,
      size: 1.5 + rand.nextDouble() * 2.5,
      color: const Color(0xAA80DEEA),
      type: ParticleType.bubble,
    );
  }

  static Particle ventParticle(Vector2 pos) {
    final rand = math.Random();
    return Particle(
      position: pos + Vector2((rand.nextDouble() - 0.5) * 12.0, (rand.nextDouble() - 0.5) * 6.0),
      velocity: Vector2((rand.nextDouble() - 0.5) * 10.0, -30.0 - rand.nextDouble() * 25.0),
      maxLife: 1.2 + rand.nextDouble() * 0.8,
      size: 2.0 + rand.nextDouble() * 3.0,
      color: const Color(0x99FF7043),
      type: ParticleType.ventSmoke,
    );
  }

  static Particle spark(Vector2 pos) {
    final rand = math.Random();
    final angle = rand.nextDouble() * 2 * math.pi;
    return Particle(
      position: pos,
      velocity: Vector2.fromAngle(angle, 40.0 + rand.nextDouble() * 60.0),
      maxLife: 0.3 + rand.nextDouble() * 0.4,
      size: 1.5 + rand.nextDouble() * 1.5,
      color: const Color(0xFFFFD54F),
      type: ParticleType.spark,
    );
  }
}

