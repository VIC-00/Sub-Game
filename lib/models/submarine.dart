import 'dart:math' as math;
import 'vector2.dart';

class Submarine {
  Vector2 position;
  Vector2 velocity;
  double heading; // Angle in radians
  final double radius; // Hitbox radius

  double hull;
  double maxHull;

  double battery;
  double maxBattery;
  double passiveRechargeRate;
  double noiseMultiplier;

  int collectedRelics;
  int totalRelics;
  int decoysRemaining;

  bool isThrusting;
  double thrusterAudioIntensity;
  double invulnerabilityTimer; // Brief invulnerability after hitting rock

  // Movement physics constants
  static const double maxSpeed = 160.0;
  static const double acceleration = 240.0;
  static const double waterDrag = 1.6; // Velocity decay per second
  static const double turnSpeed = 6.0; // Radians per second

  Submarine({
    required this.position,
    this.radius = 14.0,
    this.maxHull = 100.0,
    this.maxBattery = 100.0,
    this.passiveRechargeRate = 2.2,
    this.noiseMultiplier = 1.0,
    this.totalRelics = 3,
    this.decoysRemaining = 2,
  })  : velocity = Vector2.zero,
        heading = -math.pi / 2, // Facing upwards initially
        hull = maxHull,
        battery = maxBattery,
        collectedRelics = 0,
        isThrusting = false,
        thrusterAudioIntensity = 0.0,
        invulnerabilityTimer = 0.0;

  bool get isDead => hull <= 0;
  bool get allRelicsCollected => collectedRelics >= totalRelics;
  bool get isInvulnerable => invulnerabilityTimer > 0;
  bool get isEmergencyDrift => battery <= 0.0;

  /// Current acoustic noise emitted by submarine (0.0 to 1.0)
  double get acousticNoise {
    double base = 0.04; // Silent electric hum
    if (isThrusting) {
      base += 0.36 * (velocity.length / maxSpeed).clamp(0.0, 1.0);
    }
    return (base * noiseMultiplier).clamp(0.0, 1.0);
  }

  void update(double dt) {
    if (isDead) return;

    if (invulnerabilityTimer > 0) {
      invulnerabilityTimer = math.max(0.0, invulnerabilityTimer - dt);
    }

    // Apply water drag / friction
    velocity = velocity * math.max(0.0, 1.0 - waterDrag * dt);

    // Clamp speed (emergency drift mode caps speed to 40%)
    final allowedMaxSpeed = battery > 0 ? maxSpeed : maxSpeed * 0.40;
    final speed = velocity.length;
    if (speed > allowedMaxSpeed) {
      velocity = velocity.normalized() * allowedMaxSpeed;
    }

    // Update position
    position += velocity * dt;

    // Smoothly turn heading towards velocity if moving significantly
    if (velocity.lengthSquared > 10.0) {
      final targetHeading = velocity.angle;
      double diff = targetHeading - heading;
      // Normalize difference to [-pi, pi]
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }

      final maxTurn = turnSpeed * dt;
      if (diff.abs() <= maxTurn) {
        heading = targetHeading;
      } else {
        heading += diff.sign * maxTurn;
      }
    }

    // Passive & active battery power mechanics
    if (isThrusting) {
      if (battery > 0) {
        consumeBattery(dt * 0.85);
      }
      thrusterAudioIntensity = math.min(1.0, thrusterAudioIntensity + dt * 3.0);
    } else {
      thrusterAudioIntensity = math.max(0.0, thrusterAudioIntensity - dt * 2.0);
      // Auxiliary thermoelectric dynamo trickle recharge when still / drifting quietly
      rechargeBattery(dt * passiveRechargeRate);
    }
  }

  void thrust(Vector2 direction, double dt) {
    if (isDead) {
      isThrusting = false;
      return;
    }

    if (direction.lengthSquared > 0.001) {
      isThrusting = true;
      // If battery is 0%, emergency auxiliary drift power allows 35% thrust to reach recharge vents
      final powerFactor = battery > 0 ? 1.0 : 0.35;
      final accel = direction.normalized() * (acceleration * powerFactor) * dt;
      velocity += accel;
    } else {
      isThrusting = false;
    }
  }

  void takeDamage(double amount) {
    if (isInvulnerable || isDead) return;
    hull = math.max(0.0, hull - amount);
    invulnerabilityTimer = 0.6; // 600ms grace period to avoid continuous crushing
  }

  void repair(double amount) {
    hull = math.min(maxHull, hull + amount);
  }

  bool consumeBattery(double amount) {
    if (battery >= amount) {
      battery = math.max(0.0, battery - amount);
      return true;
    }
    battery = 0.0;
    return false;
  }

  void rechargeBattery(double amount) {
    battery = math.min(maxBattery, battery + amount);
  }

  void reset({
    required Vector2 startPos,
    double? newMaxHull,
    double? newMaxBattery,
    double? newPassiveRechargeRate,
    double? newNoiseMultiplier,
    int? newDecoys,
  }) {
    position = startPos;
    velocity = Vector2.zero;
    heading = -math.pi / 2;
    if (newMaxHull != null) maxHull = newMaxHull;
    if (newMaxBattery != null) maxBattery = newMaxBattery;
    if (newPassiveRechargeRate != null) passiveRechargeRate = newPassiveRechargeRate;
    if (newNoiseMultiplier != null) noiseMultiplier = newNoiseMultiplier;
    hull = maxHull;
    battery = maxBattery;
    collectedRelics = 0;
    decoysRemaining = newDecoys ?? 2;
    isThrusting = false;
    thrusterAudioIntensity = 0.0;
    invulnerabilityTimer = 0.0;
  }
}

