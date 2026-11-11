import 'package:flutter/material.dart';
import '../engine/game_controller.dart';
import '../models/monster.dart';

class HudOverlay extends StatelessWidget {
  final GameController controller;
  final VoidCallback onFireDecoy;

  const HudOverlay({
    super.key,
    required this.controller,
    required this.onFireDecoy,
  });

  @override
  Widget build(BuildContext context) {
    final sub = controller.world.submarine;
    final monster = controller.world.monster;

    final isMonsterAlert = monster.state == MonsterState.hunting ||
        monster.state == MonsterState.investigating;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Top Navigation & Gauges Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hull & Battery Gauges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMetricBar(
                        label: 'HULL INTEGRITY',
                        value: sub.hull / sub.maxHull,
                        textValue: '${sub.hull.toInt()}%',
                        color: sub.hull > 50
                            ? const Color(0xFF00FFC8)
                            : (sub.hull > 25 ? const Color(0xFFFFB74D) : const Color(0xFFFF1744)),
                        icon: Icons.shield,
                      ),
                      const SizedBox(height: 6),
                      _buildMetricBar(
                        label: sub.isEmergencyDrift
                            ? 'AUXILIARY DRIFT'
                            : (!sub.isThrusting && sub.battery < sub.maxBattery ? 'REACTOR (CHARGING)' : 'REACTOR BATTERY'),
                        value: sub.battery / sub.maxBattery,
                        textValue: sub.isEmergencyDrift ? '0% (IDLE TO RECHARGE)' : '${sub.battery.toInt()}%',
                        color: sub.isEmergencyDrift
                            ? const Color(0xFFFFB74D)
                            : (sub.battery > 25 ? const Color(0xFF00E5FF) : const Color(0xFFFF7043)),
                        icon: Icons.bolt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Depth & Relics Panel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xAA0A161D),
                        border: Border.all(color: const Color(0x6600FFC8)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DEPTH: ${controller.simulatedDepth.toInt()} M',
                        style: const TextStyle(
                          color: Color(0xFF80DEEA),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'RELICS: ',
                          style: TextStyle(
                            color: Color(0xFFB0BEC5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        for (int i = 0; i < sub.totalRelics; i++)
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Icon(
                              Icons.diamond,
                              size: 14,
                              color: i < sub.collectedRelics
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0x44FFFFFF),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Threat / Noise Signature Bar
            _buildThreatBar(sub.acousticNoise, monster),

            // Extraction Dock Directive Banner when all relics gathered
            if (controller.showExtractionWaypoint)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xDD00BFA5),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Color(0x8800FFC8), blurRadius: 12, spreadRadius: 1),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.black, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ALL CORES SALVAGED — PROCEED TO DOCK (${controller.distanceToExtraction.toInt()}M)',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Red Alert Monster Warning Banner
            if (isMonsterAlert)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xDDF44336),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x88FF1744), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        monster.state == MonsterState.hunting
                            ? 'HOSTILE LEVIATHAN LUNGING!'
                            : 'LEVIATHAN INVESTIGATING SOUND!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Decoy Button (Bottom Right above Controls)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: sub.decoysRemaining > 0 ? onFireDecoy : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sub.decoysRemaining > 0
                        ? const Color(0xCC0D2530)
                        : const Color(0x66181F24),
                    border: Border.all(
                      color: sub.decoysRemaining > 0
                          ? const Color(0xFFFFB74D)
                          : const Color(0x44FFFFFF),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flare,
                        size: 16,
                        color: sub.decoysRemaining > 0
                            ? const Color(0xFFFFB74D)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DECOY (${sub.decoysRemaining})',
                        style: TextStyle(
                          color: sub.decoysRemaining > 0
                              ? const Color(0xFFFFCC80)
                              : Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar({
    required String label,
    required double value,
    required String textValue,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '$label: $textValue',
              style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          width: 140,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            border: Border.all(color: color.withAlpha(100), width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreatBar(double acousticNoise, Monster monster) {
    final threatLevel = (acousticNoise * 0.5 + monster.agitation * 0.5).clamp(0.0, 1.0);
    final threatColor = threatLevel > 0.6
        ? const Color(0xFFFF1744)
        : (threatLevel > 0.3 ? const Color(0xFFFFB74D) : const Color(0xFF00FFC8));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'NOISE SIGNATURE: ',
          style: TextStyle(
            color: threatColor,
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          width: 90,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            border: Border.all(color: threatColor.withAlpha(80), width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: threatLevel,
            child: Container(color: threatColor),
          ),
        ),
      ],
    );
  }
}
