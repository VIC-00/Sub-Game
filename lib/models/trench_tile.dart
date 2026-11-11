enum TileType {
  empty,
  wall,
  jaggedRock,
  relic,
  hydrothermalVent,
  exitDock,
}

class TrenchTile {
  final int gridX;
  final int gridY;
  TileType type;
  double luminance; // 0.0 = pitch black, 1.0 = fully lit phosphor
  double hitFlash; // Extra bright flash immediately upon wave contact
  bool discovered;
  bool relicCollected;

  TrenchTile({
    required this.gridX,
    required this.gridY,
    required this.type,
    this.luminance = 0.0,
    this.hitFlash = 0.0,
    this.discovered = false,
    this.relicCollected = false,
  });

  bool get isSolid =>
      type == TileType.wall ||
      type == TileType.jaggedRock;

  bool get isHazard => type == TileType.jaggedRock;

  bool get isRelic => type == TileType.relic && !relicCollected;

  bool get isVent => type == TileType.hydrothermalVent;

  bool get isExit => type == TileType.exitDock;

  void excite(double intensity) {
    discovered = true;
    luminance = (luminance + intensity).clamp(0.0, 1.0);
    hitFlash = (hitFlash + intensity * 0.8).clamp(0.0, 1.0);
  }

  void update(double dt, {double decayRate = 0.28}) {
    if (luminance > 0) {
      luminance = (luminance - dt * decayRate).clamp(0.0, 1.0);
    }
    if (hitFlash > 0) {
      hitFlash = (hitFlash - dt * 2.5).clamp(0.0, 1.0);
    }
  }

  void reset() {
    luminance = 0.0;
    hitFlash = 0.0;
    discovered = false;
    relicCollected = false;
  }
}

