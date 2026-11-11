import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/game_world.dart';
import '../models/sonar_wave.dart';
import '../models/trench_tile.dart';

class DeepSeaPainter extends CustomPainter {
  final GameWorld world;
  final bool isChargingSonar;
  final double sonarChargeRatio;
  final double screenShake;
  final double redSeismicPulse;
  final double monsterProximity;
  final bool showExtractionWaypoint;
  final double angleToExtraction;
  final double distanceToExtraction;

  DeepSeaPainter({
    required this.world,
    required this.isChargingSonar,
    required this.sonarChargeRatio,
    this.screenShake = 0.0,
    this.redSeismicPulse = 0.0,
    this.monsterProximity = 0.0,
    this.showExtractionWaypoint = false,
    this.angleToExtraction = 0.0,
    this.distanceToExtraction = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sub = world.submarine;
    final centerScreen = Offset(size.width / 2, size.height / 2);

    // 1. Draw pitch-black abyss background
    final bgPaint = Paint()..color = const Color(0xFF03080C);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Camera transformation (centered on submarine with dynamic impact rumble)
    double shakeX = 0.0;
    double shakeY = 0.0;
    if (screenShake > 0.05) {
      shakeX = (math.Random().nextDouble() - 0.5) * screenShake * 2.0;
      shakeY = (math.Random().nextDouble() - 0.5) * screenShake * 2.0;
    }

    canvas.save();
    canvas.translate(
      centerScreen.dx - sub.position.x + shakeX,
      centerScreen.dy - sub.position.y + shakeY,
    );

    // Visible viewport bounds in world coordinates
    final viewLeft = sub.position.x - size.width / 2 - 40;
    final viewRight = sub.position.x + size.width / 2 + 40;
    final viewTop = sub.position.y - size.height / 2 - 40;
    final viewBottom = sub.position.y + size.height / 2 + 40;

    final ts = GameWorld.tileSize;
    final minGx = math.max(0, (viewLeft / ts).floor());
    final maxGx = math.min(GameWorld.gridWidth - 1, (viewRight / ts).ceil());
    final minGy = math.max(0, (viewTop / ts).floor());
    final maxGy = math.min(GameWorld.gridHeight - 1, (viewBottom / ts).ceil());

    // 3. Render trench grid tiles
    _drawTrenchTiles(canvas, minGx, maxGx, minGy, maxGy);

    // 4. Render particles (marine snow, bubbles, sparks)
    _drawParticles(canvas);

    // 5. Render sonar waves
    _drawSonarWaves(canvas);

    // 6. Render the Blind Leviathan
    _drawMonster(canvas);

    // 7. Render Submarine
    _drawSubmarine(canvas, sub);

    canvas.restore();

    // 8. Screen-space HUD effects (vignette & sonar charge ring around sub screen center)
    _drawVignette(canvas, size);

    if (isChargingSonar) {
      _drawChargingRing(canvas, centerScreen);
    }
  }

  void _drawTrenchTiles(Canvas canvas, int minGx, int maxGx, int minGy, int maxGy) {
    final ts = GameWorld.tileSize;

    final wallPaint = Paint()..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int gx = minGx; gx <= maxGx; gx++) {
      for (int gy = minGy; gy <= maxGy; gy++) {
        final tile = world.grid[gx][gy];
        if (tile.type == TileType.empty) continue;

        // Effective brightness is luminance + hit flash
        final brightness = (tile.luminance + tile.hitFlash).clamp(0.0, 1.0);
        if (brightness < 0.01) continue; // Completely pitch dark!

        final rect = Rect.fromLTWH(gx * ts, gy * ts, ts, ts);

        switch (tile.type) {
          case TileType.wall:
            // Phosphor green-cyan glow
            final alpha = (brightness * 230).toInt().clamp(0, 255);
            wallPaint.color = Color.fromARGB(alpha ~/ 3, 0, 180, 140);
            canvas.drawRect(rect, wallPaint);

            edgePaint.color = Color.fromARGB(alpha, 0, 255, 180);
            canvas.drawRect(rect, edgePaint);
            break;

          case TileType.jaggedRock:
            // Hazardous jagged spikes
            final alpha = (brightness * 255).toInt().clamp(0, 255);
            wallPaint.color = Color.fromARGB(alpha ~/ 3, 190, 40, 20);
            canvas.drawRect(rect, wallPaint);

            edgePaint.color = Color.fromARGB(alpha, 255, 70, 40);
            final path = Path()
              ..moveTo(rect.left, rect.bottom)
              ..lineTo(rect.left + ts * 0.5, rect.top + ts * 0.15)
              ..lineTo(rect.right, rect.bottom)
              ..close();
            canvas.drawPath(path, edgePaint);
            break;

          case TileType.relic:
            if (!tile.relicCollected) {
              // Ancient alien data core / relic
              final alpha = (brightness * 255).toInt().clamp(0, 255);
              final center = Offset(rect.left + ts / 2, rect.top + ts / 2);

              final relicPaint = Paint()
                ..color = Color.fromARGB(alpha, 0, 229, 255)
                ..style = PaintingStyle.fill;
              canvas.drawCircle(center, 7.0, relicPaint);

              final ringPaint = Paint()
                ..color = Color.fromARGB(alpha, 178, 255, 89)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0;
              canvas.drawCircle(center, 12.0 * brightness, ringPaint);
            }
            break;

          case TileType.hydrothermalVent:
            // Hydrothermal chimney
            final alpha = (brightness * 255).toInt().clamp(0, 255);
            final center = Offset(rect.left + ts / 2, rect.top + ts / 2);

            final ventPaint = Paint()
              ..color = Color.fromARGB(alpha, 255, 110, 0)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(center, 9.0, ventPaint);

            final heatRing = Paint()
              ..color = Color.fromARGB(alpha ~/ 2, 255, 171, 0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0;
            canvas.drawCircle(center, 15.0, heatRing);
            break;

          case TileType.exitDock:
            // Extraction Subsea Dock
            final isUnlocked = world.submarine.allRelicsCollected;
            final alpha = (brightness * 255).toInt().clamp(0, 255);

            if (isUnlocked) {
              final center = rect.center;
              final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) + 1.0) / 2.0;
              final beaconAlpha = (120 + pulse * 135).toInt().clamp(0, 255);

              final beaconPaint = Paint()
                ..color = Color.fromARGB(beaconAlpha, 0, 255, 120)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5;
              canvas.drawCircle(center, 16.0 + pulse * 6.0, beaconPaint);
              canvas.drawCircle(center, 26.0 + pulse * 10.0, beaconPaint..color = Color.fromARGB(beaconAlpha ~/ 3, 0, 255, 120));

              edgePaint.color = const Color(0xFF00FFC8);
              canvas.drawRect(rect, edgePaint);

              final dockPaint = Paint()
                ..color = const Color(0xFF00E676)
                ..style = PaintingStyle.fill;
              canvas.drawCircle(center, 8.0, dockPaint);
            } else {
              edgePaint.color = Color.fromARGB(alpha, 255, 170, 0);
              canvas.drawRect(rect, edgePaint);

              final dockPaint = Paint()
                ..color = Color.fromARGB(alpha ~/ 4, 255, 170, 0)
                ..style = PaintingStyle.fill;
              canvas.drawCircle(rect.center, 8.0, dockPaint);
            }
            break;

          default:
            break;
        }
      }
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in world.particles) {
      final baseAlpha = (p.progress * 255).toInt().clamp(0, 255);
      final hasLumi = p.luminescence > 0.01;

      final alpha = hasLumi
          ? (baseAlpha * 0.4 + p.luminescence * 0.6 * 255).toInt().clamp(0, 255)
          : (baseAlpha * 0.5).toInt().clamp(0, 255);

      final color = hasLumi
          ? Color.lerp(p.color, const Color(0xFF00FFC8), p.luminescence)!
          : p.color;

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      final size = hasLumi ? p.size * (1.0 + p.luminescence * 0.9) : p.size;
      canvas.drawCircle(p.position.toOffset(), size, paint);
    }
  }

  void _drawSonarWaves(Canvas canvas) {
    for (final wave in world.waves) {
      final intensity = wave.intensity;
      if (intensity <= 0.01) continue;

      final isLoud = wave.type == PingType.loud;
      final alpha = (intensity * 255).toInt().clamp(0, 255);
      final strokeWidth = isLoud ? (6.0 * intensity + 2.0) : (3.5 * intensity + 1.0);

      // Outer glowing aura sweep
      final auraPaint = Paint()
        ..color = wave.color.withAlpha((alpha * 0.4).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.2;
      canvas.drawCircle(wave.origin.toOffset(), wave.currentRadius, auraPaint);

      // Primary crisp wavefront ring
      final wavePaint = Paint()
        ..color = wave.color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(wave.origin.toOffset(), wave.currentRadius, wavePaint);

      // Trailing subtle phosphor secondary rings
      if (wave.currentRadius > 18.0) {
        final trailPaint = Paint()
          ..color = wave.color.withAlpha(alpha ~/ 3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isLoud ? 2.5 : 1.2;
        canvas.drawCircle(wave.origin.toOffset(), wave.currentRadius - 14.0, trailPaint);

        if (isLoud && wave.currentRadius > 35.0) {
          final echoPaint = Paint()
            ..color = const Color(0xFF00FFC8).withAlpha(alpha ~/ 5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawCircle(wave.origin.toOffset(), wave.currentRadius - 30.0, echoPaint);
        }
      }

      // If decoy countermeasure, draw flashing acoustic flare buoy at epicenter
      if (wave.isDecoy) {
        final buoyCenter = wave.origin.toOffset();
        final strobeAlpha = ((math.sin(DateTime.now().millisecondsSinceEpoch * 0.02) + 1.0) / 2.0 * 255).toInt();
        final strobePaint = Paint()
          ..color = Color.fromARGB(strobeAlpha, 255, 183, 77)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(buoyCenter, 6.0, strobePaint);

        final buoyBody = Paint()
          ..color = const Color(0xFFFF9100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(buoyCenter, 9.0, buoyBody);
      }
    }
  }

  void _drawMonster(Canvas canvas) {
    final monster = world.monster;

    // Monster is only drawn if illuminated by sonar wave or in very close contact
    if (!monster.isVisible) {
      // In pitch darkness, if close to submarine, draw terrifying faint seismic disturbance ripples
      final distToSub = monster.position.distanceTo(world.submarine.position);
      if (distToSub < 260.0) {
        final seismicAlpha = ((1.0 - distToSub / 260.0) * 80).toInt().clamp(0, 255);
        final seismicPaint = Paint()
          ..color = Color.fromARGB(seismicAlpha, 255, 23, 68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(monster.position.toOffset(), 28.0 + math.sin(distToSub) * 4.0, seismicPaint);
      }
      return;
    }

    final visibility = monster.visibilityIntensity;
    final alpha = (visibility * 255).toInt().clamp(0, 255);

    // Serpentine spine and body
    for (int i = monster.segments.length - 1; i >= 0; i--) {
      final seg = monster.segments[i];
      final isHead = (i == 0);

      // Body segment fill
      final bodyPaint = Paint()
        ..color = isHead
            ? Color.fromARGB(alpha, 230, 30, 60)
            : Color.fromARGB(alpha, (120 - i * 8).clamp(30, 150), 10, 30)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(seg.position.toOffset(), seg.radius, bodyPaint);

      // Bioluminescent glowing ridge
      final ridgePaint = Paint()
        ..color = Color.fromARGB(alpha, 255, 82, 82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(seg.position.toOffset(), seg.radius * 0.6, ridgePaint);
    }

    // Menacing Leviathan head mandibles
    final head = monster.segments[0];
    final headOffset = head.position.toOffset();
    canvas.save();
    canvas.translate(headOffset.dx, headOffset.dy);
    canvas.rotate(monster.heading);

    final mandiblePaint = Paint()
      ..color = Color.fromARGB(alpha, 255, 23, 68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Left mandible
    canvas.drawLine(const Offset(6, -6), const Offset(20, -12), mandiblePaint);
    canvas.drawLine(const Offset(20, -12), const Offset(24, -4), mandiblePaint);

    // Right mandible
    canvas.drawLine(const Offset(6, 6), const Offset(20, 12), mandiblePaint);
    canvas.drawLine(const Offset(20, 12), const Offset(24, 4), mandiblePaint);

    // Pale blind eyes
    final eyePaint = Paint()
      ..color = Color.fromARGB(alpha, 255, 255, 255)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(10, -5), 2.2, eyePaint);
    canvas.drawCircle(const Offset(10, 5), 2.2, eyePaint);

    canvas.restore();
  }

  void _drawSubmarine(Canvas canvas, dynamic sub) {
    final subPos = sub.position.toOffset();

    canvas.save();
    canvas.translate(subPos.dx, subPos.dy);
    canvas.rotate(sub.heading);

    // 1. Directional soft headlights cone into the dark abyss
    final lightCone = Path()
      ..moveTo(12, 0)
      ..lineTo(90, -35)
      ..lineTo(90, 35)
      ..close();
    final lightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x3500FFC8), Color(0x0000FFC8)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(const Rect.fromLTWH(12, -35, 78, 70));
    canvas.drawPath(lightCone, lightPaint);

    // 2. Submarine hull
    final hullPaint = Paint()
      ..color = const Color(0xFF1B2A32)
      ..style = PaintingStyle.fill;
    final hullOutline = Paint()
      ..color = const Color(0xFF00FFC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Oval submersible hull
    final hullRect = const Rect.fromLTWH(-16, -11, 32, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(hullRect, const Radius.circular(8)), hullPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(hullRect, const Radius.circular(8)), hullOutline);

    // Cockpit observation glass dome
    final glassPaint = Paint()
      ..color = const Color(0xDD00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(4, 0), 5.5, glassPaint);

    // Propeller rotor at the back
    final propPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-16, -7), const Offset(-16, 7), propPaint);

    canvas.restore();
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: const [
          Colors.transparent,
          Color(0x66000000),
          Color(0xDD020508),
        ],
        stops: const [0.55, 0.85, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    // 1. Red seismic shockwave overlay when a loud ping alerts the creature
    if (redSeismicPulse > 0.01) {
      final pulseAlpha = (redSeismicPulse * 180).toInt().clamp(0, 255);
      final borderPaint = Paint()
        ..color = Color.fromARGB(pulseAlpha, 255, 23, 68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;
      canvas.drawRect(rect, borderPaint);

      final center = Offset(size.width / 2, size.height / 2);
      final shockwaveR = (1.0 - redSeismicPulse) * (size.shortestSide * 0.65);
      final ringPaint = Paint()
        ..color = Color.fromARGB(pulseAlpha, 255, 23, 68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(center, shockwaveR, ringPaint);
    }

    // 2. Proximity warning pulsing vignette when monster is in hunting range
    if (monsterProximity > 0.01) {
      final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch * 0.01) + 1.0) / 2.0;
      final dangerAlpha = ((monsterProximity * 0.6 + pulse * 0.4 * monsterProximity) * 190).toInt().clamp(0, 255);
      final dangerPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            Color.fromARGB(dangerAlpha ~/ 4, 255, 23, 68),
            Color.fromARGB(dangerAlpha, 255, 23, 68),
          ],
          stops: const [0.55, 0.80, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, dangerPaint);
    }

    // 3. Extraction Dock Waypoint Indicator
    if (showExtractionWaypoint) {
      _drawWaypointArrow(canvas, size);
    }
  }

  void _drawWaypointArrow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowDist = math.min(size.width, size.height) * 0.42;
    final arrowOffset = center + Offset(math.cos(angleToExtraction) * arrowDist, math.sin(angleToExtraction) * arrowDist);

    canvas.save();
    canvas.translate(arrowOffset.dx, arrowOffset.dy);
    canvas.rotate(angleToExtraction);

    final arrowPaint = Paint()
      ..color = const Color(0xFF00FFC8)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(14, 0)
      ..lineTo(-10, -10)
      ..lineTo(-4, 0)
      ..lineTo(-10, 10)
      ..close();
    canvas.drawPath(path, arrowPaint);

    canvas.restore();
  }

  void _drawChargingRing(Canvas canvas, Offset center) {
    final charge = sonarChargeRatio;
    final radius = 34.0 + charge * 14.0;

    Color ringColor;
    if (charge < 0.25) {
      ringColor = const Color(0xFF00FFC8);
    } else if (charge < 0.70) {
      ringColor = const Color(0xFF00E5FF);
    } else {
      ringColor = const Color(0xFFFF1744); // Warning loud noise!
    }

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final sweepAngle = charge * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DeepSeaPainter oldDelegate) => true;
}
