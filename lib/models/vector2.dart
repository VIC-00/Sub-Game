import 'dart:math' as math;
import 'dart:ui';

/// 2D Vector for game physics and canvas rendering.
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  static const Vector2 zero = Vector2(0, 0);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);
  Vector2 operator -() => Vector2(-x, -y);

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  double distanceTo(Vector2 other) => (this - other).length;
  double distanceSquaredTo(Vector2 other) => (this - other).lengthSquared;

  Vector2 normalized() {
    final len = length;
    if (len == 0) return Vector2.zero;
    return Vector2(x / len, y / len);
  }

  double dot(Vector2 other) => x * other.x + y * other.y;

  /// Angle in radians relative to positive X-axis
  double get angle => math.atan2(y, x);

  static Vector2 fromAngle(double radians, [double length = 1.0]) {
    return Vector2(math.cos(radians) * length, math.sin(radians) * length);
  }

  Vector2 rotate(double radians) {
    final cosA = math.cos(radians);
    final sinA = math.sin(radians);
    return Vector2(x * cosA - y * sinA, x * sinA + y * cosA);
  }

  Vector2 lerp(Vector2 other, double t) {
    return Vector2(x + (other.x - x) * t, y + (other.y - y) * t);
  }

  Offset toOffset() => Offset(x, y);

  @override
  String toString() => 'Vector2(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2 &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

