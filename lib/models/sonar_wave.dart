import 'package:flutter/material.dart';
import 'vector2.dart';

enum PingType {
  soft,
  medium,
  loud,
  decoy,
}

class SonarWave {
  final String id;
  final Vector2 origin;
  final PingType type;
  final double maxRadius;
  final double expansionSpeed;
  final double noiseLevel; // 0.0 (silent) to 1.0 (deafening)
  final Color color;
  final bool isDecoy;

  double currentRadius;
  bool isFinished;

  SonarWave({
    required this.id,
    required this.origin,
    required this.type,
    required this.maxRadius,
    required this.expansionSpeed,
    required this.noiseLevel,
    required this.color,
    this.currentRadius = 0.0,
    this.isFinished = false,
    this.isDecoy = false,
  });

  /// Factory for quick tap / soft ping
  factory SonarWave.soft({required Vector2 origin, required String id}) {
    return SonarWave(
      id: id,
      origin: origin,
      type: PingType.soft,
      maxRadius: 200.0,
      expansionSpeed: 240.0,
      noiseLevel: 0.25,
      color: const Color(0xFF00FFC8), // Neon cyan-green
    );
  }

  /// Factory for medium charge ping
  factory SonarWave.medium({required Vector2 origin, required String id}) {
    return SonarWave(
      id: id,
      origin: origin,
      type: PingType.medium,
      maxRadius: 360.0,
      expansionSpeed: 280.0,
      noiseLevel: 0.60,
      color: const Color(0xFF00E5FF), // Intense cyan
    );
  }

  /// Factory for max charge / loud ping (high risk, high reward)
  factory SonarWave.loud({required Vector2 origin, required String id}) {
    return SonarWave(
      id: id,
      origin: origin,
      type: PingType.loud,
      maxRadius: 600.0,
      expansionSpeed: 340.0,
      noiseLevel: 1.0,
      color: const Color(0xFF40C4FF), // Deep ocean electric blue
    );
  }

  /// Factory for acoustic decoy launch
  factory SonarWave.decoy({required Vector2 origin, required String id}) {
    return SonarWave(
      id: id,
      origin: origin,
      type: PingType.decoy,
      maxRadius: 400.0,
      expansionSpeed: 200.0,
      noiseLevel: 0.95,
      color: const Color(0xFFFFB74D), // Warning amber
      isDecoy: true,
    );
  }

  /// Current intensity from 1.0 down to 0.0 as it nears max radius
  double get intensity {
    if (maxRadius <= 0) return 0.0;
    final progress = (currentRadius / maxRadius).clamp(0.0, 1.0);
    return 1.0 - progress;
  }

  void update(double dt) {
    if (isFinished) return;
    currentRadius += expansionSpeed * dt;
    if (currentRadius >= maxRadius) {
      currentRadius = maxRadius;
      isFinished = true;
    }
  }
}

