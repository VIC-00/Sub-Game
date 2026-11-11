import 'package:flutter/material.dart';
import '../engine/game_controller.dart';

class VictoryDialog extends StatelessWidget {
  final GameController controller;
  final VoidCallback onPlayAgain;

  const VictoryDialog({
    super.key,
    required this.controller,
    required this.onPlayAgain,
  });

  String _calculateStealthRating() {
    final pings = controller.pingsCount;
    if (pings <= 8) return 'RANK S: ABYSSAL GHOST';
    if (pings <= 18) return 'RANK A: SILENT DIVER';
    if (pings <= 30) return 'RANK B: ECHO HUNTER';
    return 'RANK C: SURVIVOR';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (controller.playTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (controller.playTime.toInt() % 60).toString().padLeft(2, '0');

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xEE09141A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00FFC8), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6600FFC8),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF00FFC8),
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'EXTRACTION ACCOMPLISHED',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FFC8),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All Hadal relics recovered. The submersible has docked successfully at the extraction platform.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x3300FFC8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x6600FFC8)),
              ),
              child: Text(
                _calculateStealthRating(),
                style: const TextStyle(
                  color: Color(0xFF80DEEA),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x44000000),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Column(
                children: [
                  _buildStatRow('EXPEDITION DEPTH', '${controller.simulatedDepth.toInt()} M'),
                  const SizedBox(height: 6),
                  _buildStatRow(
                    'RELICS SALVAGED',
                    '${controller.world.submarine.collectedRelics} / ${controller.world.submarine.totalRelics}',
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow('SONAR PINGS USED', '${controller.pingsCount}'),
                  const SizedBox(height: 6),
                  _buildStatRow('SCRAP EARNED', '+${controller.scrapEarnedThisRun} ⚙️'),
                  const SizedBox(height: 6),
                  _buildStatRow('MISSION DURATION', '$minutes:$seconds'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPlayAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'RETURN TO BASE & UPGRADE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF90A4AE),
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00FFC8),
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

