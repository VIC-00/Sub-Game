import 'package:flutter/material.dart';
import '../models/vector2.dart';

class VirtualJoystick extends StatefulWidget {
  final ValueChanged<Vector2> onDirectionChanged;
  final double radius;

  const VirtualJoystick({
    super.key,
    required this.onDirectionChanged,
    this.radius = 65.0,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _dragOffset = Offset.zero;

  void _handleDrag(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    final dist = delta.distance;

    final maxDist = widget.radius;
    Offset clampedOffset;
    if (dist <= maxDist) {
      clampedOffset = delta;
    } else {
      clampedOffset = delta * (maxDist / dist);
    }

    setState(() {
      _dragOffset = clampedOffset;
    });

    final normalized = Vector2(
      clampedOffset.dx / maxDist,
      clampedOffset.dy / maxDist,
    );
    widget.onDirectionChanged(normalized);
  }

  void _handleDragEnd() {
    setState(() {
      _dragOffset = Offset.zero;
    });
    widget.onDirectionChanged(Vector2.zero);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => _handleDrag(details.localPosition, Size(size, size)),
      onPanUpdate: (details) => _handleDrag(details.localPosition, Size(size, size)),
      onPanEnd: (_) => _handleDragEnd(),
      onPanCancel: () => _handleDragEnd(),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _JoystickPainter(
            radius: widget.radius,
            dragOffset: _dragOffset,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final double radius;
  final Offset dragOffset;

  _JoystickPainter({required this.radius, required this.dragOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer circular boundary
    final basePaint = Paint()
      ..color = const Color(0x3300FFC8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    final borderPaint = Paint()
      ..color = const Color(0x8800FFC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Inner crosshairs
    final linePaint = Paint()
      ..color = const Color(0x4400FFC8)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius * 0.4, center.dy), Offset(center.dx + radius * 0.4, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius * 0.4), Offset(center.dx, center.dy + radius * 0.4), linePaint);

    // Thumb stick knob
    final thumbPos = center + dragOffset;
    final thumbFill = Paint()
      ..color = const Color(0xCC00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thumbPos, 22.0, thumbFill);

    final thumbBorder = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(thumbPos, 22.0, thumbBorder);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.dragOffset != dragOffset;
}
