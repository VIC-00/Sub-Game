import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/sound_synthesizer.dart';
import '../engine/game_controller.dart';
import '../models/upgrade_state.dart';
import '../models/vector2.dart';
import '../rendering/deep_sea_painter.dart';
import 'game_over_dialog.dart';
import 'hud_overlay.dart';
import 'sonar_button.dart';
import 'surface_base_screen.dart';
import 'victory_dialog.dart';
import 'virtual_joystick.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameController _controller;
  final UpgradeState _upgradeState = UpgradeState();
  final FocusNode _keyboardFocus = FocusNode();
  bool _showingSurfaceBase = false;

  // Desktop keyboard movement tracking
  bool _keyUp = false;
  bool _keyDown = false;
  bool _keyLeft = false;
  bool _keyRight = false;

  @override
  void initState() {
    super.initState();
    _upgradeState.load();
    _controller = GameController(vsync: this, upgradeState: _upgradeState);

    // Audio / Haptic hooks
    _controller.onPingFired = SoundSynthesizer.playPing;
    _controller.onLoudPingFired = SoundSynthesizer.playLoudPing;
    _controller.onDecoyFired = SoundSynthesizer.playDecoy;
    _controller.onRelicCollected = SoundSynthesizer.playRelicCollected;
    _controller.onHullDamage = SoundSynthesizer.playHullImpact;
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _updateKeyboardInput() {
    double dx = 0.0;
    double dy = 0.0;
    if (_keyLeft) dx -= 1.0;
    if (_keyRight) dx += 1.0;
    if (_keyUp) dy -= 1.0;
    if (_keyDown) dy += 1.0;

    final vec = Vector2(dx, dy);
    _controller.updateJoystick(vec.lengthSquared > 0 ? vec.normalized() : Vector2.zero);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _keyUp = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _keyDown = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _keyLeft = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _keyRight = true;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        if (!_controller.isChargingSonar) {
          _controller.startSonarCharge();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
        _controller.fireDecoy();
      }
      _updateKeyboardInput();
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _keyUp = false;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _keyDown = false;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _keyLeft = false;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _keyRight = false;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _controller.releaseSonarCharge();
      }
      _updateKeyboardInput();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showHowToPlay() {
    _controller.pause();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFA0B161E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00FFC8)),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF00FFC8)),
            SizedBox(width: 8),
            Text(
              'MISSION DIRECTIVES',
              style: TextStyle(
                color: Color(0xFF00FFC8),
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• THE PITCH-BLACK TRENCH:\n'
              'Navigate the abyssal trench. The waters are pitch dark; terrain is only revealed when hit by sonar echoes.',
              style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• TAP-TO-PING (QUICK TAP):\n'
              'Emits a soft, low-range ping. Keeps noise low and consumes minimal battery.',
              style: TextStyle(color: Color(0xFF80DEEA), fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• HOLD-TO-CHARGE (LOUD PING):\n'
              'Fires a high-energy deep pulse that reveals large areas of the trench. WARNING: Loud pings attract the Blind Leviathan directly to the sound!',
              style: TextStyle(color: Color(0xFFFF8A80), fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• THE BLIND LEVIATHAN:\n'
              'The creature has no eyes—it hunts by acoustic noise! Drift quietly without thrusters to evade it, or deploy decoys to lure it away.',
              style: TextStyle(color: Color(0xFFFFAB91), fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• OBJECTIVE:\n'
              'Collect all 3 ancient Data Cores (diamonds) and escape to the Subsea Dock (green square) to extract.',
              style: TextStyle(color: Color(0xFFA7FFEB), fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.resume();
            },
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(color: Color(0xFF00FFC8), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showingSurfaceBase) {
      return SurfaceBaseScreen(
        upgradeState: _upgradeState,
        lastRunScrap: _controller.scrapEarnedThisRun,
        lastRunWon: _controller.status == GameStatus.won,
        onLaunchExpedition: () {
          setState(() {
            _showingSurfaceBase = false;
          });
          _controller.restart(); // Fresh procedural map and newly applied upgrades!
        },
      );
    }

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // 1. World Canvas Rendering
                Positioned.fill(
                  child: CustomPaint(
                    painter: DeepSeaPainter(
                      world: _controller.world,
                      isChargingSonar: _controller.isChargingSonar,
                      sonarChargeRatio: _controller.sonarChargeRatio,
                      screenShake: _controller.screenShake,
                      redSeismicPulse: _controller.redSeismicPulse,
                      monsterProximity: _controller.monsterProximity,
                      showExtractionWaypoint: _controller.showExtractionWaypoint,
                      angleToExtraction: _controller.angleToExtraction,
                      distanceToExtraction: _controller.distanceToExtraction,
                    ),
                  ),
                ),

                // 2. HUD Overlay (Status, Depth, Battery, Threat)
                Positioned.fill(
                  child: HudOverlay(
                    controller: _controller,
                    onFireDecoy: _controller.fireDecoy,
                  ),
                ),

                // 3. Mobile Touch Controls (Joystick on left, Sonar on right)
                if (_controller.status == GameStatus.playing)
                  Positioned(
                    left: 24,
                    bottom: 24,
                    child: VirtualJoystick(
                      onDirectionChanged: _controller.updateJoystick,
                    ),
                  ),

                if (_controller.status == GameStatus.playing)
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: SonarButton(
                      onTapDown: _controller.startSonarCharge,
                      onTapUp: _controller.releaseSonarCharge,
                      isCharging: _controller.isChargingSonar,
                      chargeRatio: _controller.sonarChargeRatio,
                      battery: _controller.world.submarine.battery,
                    ),
                  ),

                // Top right Controls: Base, Sound Toggle & Help / Directives
                Positioned(
                  top: 40,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.build_circle_outlined, color: Color(0xAA00FFC8)),
                        onPressed: () {
                          _controller.pause();
                          setState(() {
                            _showingSurfaceBase = true;
                          });
                        },
                        tooltip: 'Surface Base',
                      ),
                      IconButton(
                        icon: Icon(
                          SoundSynthesizer.soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: const Color(0xAA00FFC8),
                        ),
                        onPressed: () {
                          setState(() {
                            SoundSynthesizer.soundEnabled = !SoundSynthesizer.soundEnabled;
                          });
                        },
                        tooltip: 'Sound Toggle',
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Color(0xAA00FFC8)),
                        onPressed: _showHowToPlay,
                        tooltip: 'Directives',
                      ),
                    ],
                  ),
                ),

                // 4. Modal Overlays (Game Over / Victory)
                if (_controller.status == GameStatus.gameOver)
                  GameOverDialog(
                    controller: _controller,
                    onRestart: () {
                      setState(() {
                        _showingSurfaceBase = true;
                      });
                    },
                  ),

                if (_controller.status == GameStatus.won)
                  VictoryDialog(
                    controller: _controller,
                    onPlayAgain: () {
                      setState(() {
                        _showingSurfaceBase = true;
                      });
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

