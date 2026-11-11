import 'dart:math' as math;
import 'vector2.dart';

enum MonsterState {
  dormant,
  lurking,
  investigating,
  hunting,
  searching,
  disoriented,
}

class MonsterSegment {
  Vector2 position;
  double radius;

  MonsterSegment({required this.position, required this.radius});
}

class Monster {
  Vector2 position;
  Vector2 velocity;
  double heading;
  MonsterState state;

  Vector2? targetNoisePosition;
  double stateTimer;
  double revealedTimer; // How long it stays visible after being hit by a sonar wave
  double agitation; // 0.0 to 1.0 (how aggressive/fast it moves)

  // Serpentine body segments for undulating rendering
  final List<MonsterSegment> segments;
  static const int segmentCount = 9;
  static const double segmentSpacing = 16.0;

  // Speeds
  static const double lurkSpeed = 55.0;
  static const double investigateSpeed = 140.0;
  static const double huntSpeed = 195.0;

  Monster({
    required this.position,
  })  : velocity = Vector2.zero,
        heading = 0.0,
        state = MonsterState.dormant,
        targetNoisePosition = null,
        stateTimer = 0.0,
        revealedTimer = 0.0,
        agitation = 0.0,
        segments = List.generate(
          segmentCount,
          (i) => MonsterSegment(
            position: position - Vector2(i * segmentSpacing, 0),
            radius: (segmentCount - i * 0.7).clamp(4.0, 18.0),
          ),
        );

  bool get isVisible => revealedTimer > 0.0;
  double get visibilityIntensity => (revealedTimer / 2.0).clamp(0.0, 1.0);

  /// Called when a sonar wave hits the monster
  void pingHit(double intensity) {
    revealedTimer = math.max(revealedTimer, 2.2 * intensity);
  }

  /// Hear an acoustic event at a specific location
  void hearSound(Vector2 noiseOrigin, double noiseLevel) {
    final dist = position.distanceTo(noiseOrigin);
    // Hearing radius scales with noise level (soft ping ~220px, loud ping ~1000px)
    final hearingRange = 160.0 + noiseLevel * 840.0;

    if (dist <= hearingRange) {
      targetNoisePosition = noiseOrigin;
      agitation = math.min(1.0, agitation + noiseLevel * 0.7);

      if (noiseLevel >= 0.7) {
        // High acoustic trigger! The beast immediately surges toward the sound epicenter
        state = MonsterState.investigating;
        stateTimer = 9.0;
        final desiredAngle = (noiseOrigin - position).angle;
        heading = desiredAngle;
      } else if (state == MonsterState.dormant || state == MonsterState.lurking || state == MonsterState.searching) {
        state = MonsterState.investigating;
        stateTimer = 7.0;
      } else if (state == MonsterState.investigating) {
        stateTimer = 7.0;
      }
    }
  }

  void update(double dt, Vector2 submarinePos, double subNoise) {
    stateTimer = math.max(0.0, stateTimer - dt);
    revealedTimer = math.max(0.0, revealedTimer - dt);
    agitation = math.max(0.0, agitation - dt * 0.05);

    final distToSub = position.distanceTo(submarinePos);

    // If extremely close to submarine or submarine is thrusting loudly nearby
    if (distToSub < 180.0 && subNoise > 0.2) {
      state = MonsterState.hunting;
      targetNoisePosition = submarinePos;
      stateTimer = 5.0;
    }

    // Determine target and speed based on state
    Vector2? destination;
    double currentSpeed = lurkSpeed;

    switch (state) {
      case MonsterState.dormant:
        velocity = velocity * 0.9;
        break;

      case MonsterState.lurking:
        currentSpeed = lurkSpeed;
        if (targetNoisePosition == null || stateTimer <= 0) {
          // Slowly wander or patrol
          final wanderAngle = heading + (math.Random().nextDouble() - 0.5) * 0.8;
          destination = position + Vector2.fromAngle(wanderAngle, 100);
        } else {
          destination = targetNoisePosition;
        }
        break;

      case MonsterState.investigating:
        currentSpeed = investigateSpeed + agitation * 30.0;
        destination = targetNoisePosition;
        if (destination != null && position.distanceTo(destination) < 30.0) {
          // Reached noise epicenter, start searching around
          state = MonsterState.searching;
          stateTimer = 4.0;
        }
        if (stateTimer <= 0) {
          state = MonsterState.lurking;
        }
        break;

      case MonsterState.hunting:
        currentSpeed = huntSpeed + agitation * 40.0;
        destination = submarinePos; // Aggressively homing in on submarine!
        if (distToSub > 320.0 || stateTimer <= 0) {
          state = MonsterState.searching;
          stateTimer = 3.5;
        }
        break;

      case MonsterState.searching:
        currentSpeed = lurkSpeed * 1.2;
        // Swim in erratic circular search pattern
        final searchAngle = heading + 1.2 * dt;
        destination = position + Vector2.fromAngle(searchAngle, 60.0);
        if (stateTimer <= 0) {
          state = MonsterState.lurking;
        }
        break;

      case MonsterState.disoriented:
        currentSpeed = lurkSpeed * 0.5;
        // Swim away from decoy
        if (stateTimer <= 0) {
          state = MonsterState.lurking;
        }
        break;
    }

    // Move toward destination
    if (destination != null && state != MonsterState.dormant) {
      final toDest = destination - position;
      if (toDest.lengthSquared > 1.0) {
        final targetHeading = toDest.angle;
        double diff = targetHeading - heading;
        while (diff < -math.pi) {
          diff += 2 * math.pi;
        }
        while (diff > math.pi) {
          diff -= 2 * math.pi;
        }

        // Turn towards target
        const turnRate = 3.2;
        if (diff.abs() <= turnRate * dt) {
          heading = targetHeading;
        } else {
          heading += diff.sign * turnRate * dt;
        }

        final desiredVel = Vector2.fromAngle(heading, currentSpeed);
        velocity = velocity.lerp(desiredVel, dt * 2.5);
      }
    }

    // Apply movement
    position += velocity * dt;

    // Update body segments (inverse kinematics / follow the leader)
    segments[0].position = position;
    for (int i = 1; i < segments.length; i++) {
      final prev = segments[i - 1].position;
      final curr = segments[i].position;
      final diff = curr - prev;
      final dist = diff.length;
      if (dist > 0.001) {
        segments[i].position = prev + diff.normalized() * segmentSpacing;
      }
    }
  }

  void reset(Vector2 spawnPos) {
    position = spawnPos;
    velocity = Vector2.zero;
    heading = 0.0;
    state = MonsterState.dormant;
    targetNoisePosition = null;
    stateTimer = 0.0;
    revealedTimer = 0.0;
    agitation = 0.0;
    for (int i = 0; i < segments.length; i++) {
      segments[i].position = spawnPos - Vector2(i * segmentSpacing, 0);
    }
  }
}
