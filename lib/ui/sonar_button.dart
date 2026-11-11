import 'dart:math' as math;
import 'package:flutter/material.dart';

class SonarButton extends StatelessWidget {
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final bool isCharging;
  final double chargeRatio;
  final double battery;

  const SonarButton({
    super.key,
    required this.onTapDown,
    required this.onTapUp,
    required this.isCharging,
    required this.chargeRatio,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBattery = battery > 4.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (hasBattery) onTapDown();
      },
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapUp(),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isCharging
                  ? (chargeRatio > 0.7 ? const Color(0x66FF1744) : const Color(0x6600E5FF))
                  : const Color(0x3300FFC8),
              blurRadius: isCharging ? 24.0 : 12.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _SonarButtonPainter(
            isCharging: isCharging,
            chargeRatio: chargeRatio,
            hasBattery: hasBattery,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radar,
                  size: 32,
                  color: !hasBattery
                      ? Colors.grey
                      : (isCharging && chargeRatio > 0.7
                          ? const Color(0xFFFF1744)
                          : const Color(0xFF00FFC8)),
                ),
                const SizedBox(height: 2),
                Text(
                  !hasBattery
                      ? 'RECHARGING'
                      : (isCharging
                          ? (chargeRatio > 0.7 ? 'LOUD PING!' : 'CHARGING')
                          : 'SONAR'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: !hasBattery
                        ? Colors.grey
                        : (isCharging && chargeRatio > 0.7
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF80DEEA)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SonarButtonPainter extends CustomPainter {
  final bool isCharging;
  final double chargeRatio;
  final bool hasBattery;

  _SonarButtonPainter({
    required this.isCharging,
    required this.chargeRatio,
    required this.hasBattery,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = hasBattery ? const Color(0xDD0A1E24) : const Color(0xDD121518)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Outer border
    final borderPaint = Paint()
      ..color = hasBattery ? const Color(0x8800FFC8) : const Color(0x33888888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Charge progress arc
    if (isCharging && hasBattery) {
      Color arcColor;
      if (chargeRatio < 0.25) {
        arcColor = const Color(0xFF00FFC8);
      } else if (chargeRatio < 0.70) {
        arcColor = const Color(0xFF00E5FF);
      } else {
        arcColor = const Color(0xFFFF1744); // Deafening alert
      }

      final progressPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        chargeRatio * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SonarButtonPainter oldDelegate) =>
      oldDelegate.isCharging != isCharging ||
      oldDelegate.chargeRatio != chargeRatio ||
      oldDelegate.hasBattery != hasBattery;
}

