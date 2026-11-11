import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../audio/sound_synthesizer.dart';
import '../models/sonar_wave.dart';
import '../models/upgrade_state.dart';
import '../models/vector2.dart';
import 'game_world.dart';
import 'sonar_system.dart';
import 'monster_ai.dart';
import 'collision_system.dart';

enum GameStatus {
  playing,
  paused,
  won,
  gameOver,
}

class GameController extends ChangeNotifier {
  late GameWorld world;
  final SonarSystem sonarSystem = SonarSystem();
  final MonsterAI monsterAI = MonsterAI();
  final CollisionSystem collisionSystem = CollisionSystem();
  final UpgradeState upgradeState;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  GameStatus status = GameStatus.playing;

  // Input states
  Vector2 joystickInput = Vector2.zero;
  bool isChargingSonar = false;
  double sonarChargeRatio = 0.0; // 0.0 to 1.0
  static const double maxChargeDuration = 1.4; // Seconds to reach loud ping

  // Atmosphere / metrics
  double simulatedDepth = 8450.0; // Meters
  double playTime = 0.0;
  int pingsCount = 0;
  int scrapEarnedThisRun = 0;
  double screenShake = 0.0; // Dynamic camera impact/rumble feedback
  double redSeismicPulse = 0.0; // Red seismic pulse triggered by loud pings
  double monsterProximity = 0.0; // 0.0 to 1.0 proximity warning
  double _heartbeatTimer = 0.0;

  bool get showExtractionWaypoint => world.submarine.allRelicsCollected && !world.isVictory;
  double get distanceToExtraction => world.submarine.position.distanceTo(world.exitDockPos);
  double get angleToExtraction => (world.exitDockPos - world.submarine.position).angle;

  // Callbacks for sound and haptics
  VoidCallback? onPingFired;
  VoidCallback? onLoudPingFired;
  VoidCallback? onDecoyFired;
  VoidCallback? onRelicCollected;
  VoidCallback? onMonsterLunge;
  VoidCallback? onHullDamage;

  GameController({TickerProvider? vsync, UpgradeState? upgradeState})
      : upgradeState = upgradeState ?? UpgradeState() {
    world = GameWorld();
    _applyUpgradesToSubmarine();
    if (vsync != null) {
      _ticker = vsync.createTicker(_tick);
      _ticker!.start();
    }
  }

  void _applyUpgradesToSubmarine() {
    world.submarine.reset(
      startPos: world.submarineStartPos,
      newMaxHull: upgradeState.maxHull,
      newMaxBattery: upgradeState.maxBattery,
      newPassiveRechargeRate: 2.2 * upgradeState.passiveRechargeMultiplier,
      newNoiseMultiplier: upgradeState.noiseMultiplier,
      newDecoys: upgradeState.startingDecoys,
    );
  }

  void attachTicker(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker(_tick);
    _ticker!.start();
  }

  void start() {
    status = GameStatus.playing;
    _ticker?.start();
    notifyListeners();
  }

  void pause() {
    status = GameStatus.paused;
    _ticker?.stop();
    notifyListeners();
  }

  void resume() {
    status = GameStatus.playing;
    _lastTick = Duration.zero;
    _ticker?.start();
    notifyListeners();
  }

  void restart([int? seed]) {
    world.initWorld(seed);
    status = GameStatus.playing;
    joystickInput = Vector2.zero;
    isChargingSonar = false;
    sonarChargeRatio = 0.0;
    simulatedDepth = 8450.0;
    playTime = 0.0;
    pingsCount = 0;
    scrapEarnedThisRun = 0;
    _lastTick = Duration.zero;
    _applyUpgradesToSubmarine();
    notifyListeners();
  }

  void updateJoystick(Vector2 input) {
    joystickInput = input;
  }

  void startSonarCharge() {
    if (status != GameStatus.playing) return;
    isChargingSonar = true;
    sonarChargeRatio = 0.0;
  }

  void updateSonarCharge(double dt) {
    if (isChargingSonar) {
      sonarChargeRatio = (sonarChargeRatio + dt / maxChargeDuration).clamp(0.0, 1.0);
    }
  }

  void releaseSonarCharge() {
    if (!isChargingSonar || status != GameStatus.playing) return;
    isChargingSonar = false;

    PingType type;
    if (sonarChargeRatio < 0.25) {
      type = PingType.soft;
      onPingFired?.call();
    } else if (sonarChargeRatio < 0.70) {
      type = PingType.medium;
      onPingFired?.call();
    } else {
      type = PingType.loud;
      screenShake = 12.0;
      redSeismicPulse = 1.0;
      SoundSynthesizer.playMonsterAlert();
      onLoudPingFired?.call();
    }

    final wave = sonarSystem.emitPing(world, type);
    if (wave != null) {
      pingsCount++;
    }
    sonarChargeRatio = 0.0;
    notifyListeners();
  }

  void fireDecoy() {
    if (status != GameStatus.playing) return;
    final wave = sonarSystem.emitPing(world, PingType.decoy);
    if (wave != null) {
      onDecoyFired?.call();
      notifyListeners();
    }
  }

  void _tick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    // Cap delta time to prevent physics tunneling
    final clampedDt = math.min(dt, 0.05);

    if (status == GameStatus.playing) {
      _updateGame(clampedDt);
      notifyListeners();
    }
  }

  void _updateGame(double dt) {
    playTime += dt;
    simulatedDepth += world.submarine.velocity.length * dt * 0.05;
    if (screenShake > 0) {
      screenShake = math.max(0.0, screenShake - dt * 10.0);
    }
    if (redSeismicPulse > 0) {
      redSeismicPulse = math.max(0.0, redSeismicPulse - dt * 1.4);
    }

    // Monster proximity check & rising heartbeat audio
    final distToMonster = world.submarine.position.distanceTo(world.monster.position);
    if (distToMonster < 360.0 && !world.submarine.isDead) {
      monsterProximity = (1.0 - distToMonster / 360.0).clamp(0.0, 1.0);
      _heartbeatTimer += dt;
      final interval = 1.3 - monsterProximity * 0.95; // 1.3s down to 0.35s
      if (_heartbeatTimer >= interval) {
        _heartbeatTimer = 0.0;
        SoundSynthesizer.playHeartbeat();
      }
    } else {
      monsterProximity = 0.0;
      _heartbeatTimer = 0.0;
    }

    // Update sonar charge
    updateSonarCharge(dt);

    // Apply movement
    world.submarine.thrust(joystickInput, dt);
    world.submarine.update(dt);

    // Run systems
    final prevRelics = world.submarine.collectedRelics;
    final prevHull = world.submarine.hull;

    collisionSystem.update(world, dt);
    sonarSystem.update(world, dt);
    monsterAI.update(world, dt);
    world.updateParticles(dt);

    // Check callbacks
    if (world.submarine.collectedRelics > prevRelics) {
      scrapEarnedThisRun += 60; // 60 Scrap per relic collected
      onRelicCollected?.call();
    }
    if (world.submarine.hull < prevHull) {
      screenShake = 8.0;
      onHullDamage?.call();
    }

    // Check game over / victory
    if (world.submarine.isDead && status != GameStatus.gameOver) {
      status = GameStatus.gameOver;
      upgradeState.addScrap(scrapEarnedThisRun);
    } else if (world.isVictory && status != GameStatus.won) {
      status = GameStatus.won;
      scrapEarnedThisRun += 120; // 120 Scrap extraction mission bonus!
      upgradeState.addScrap(scrapEarnedThisRun);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

