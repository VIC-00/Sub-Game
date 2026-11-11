import 'package:flutter/material.dart';
import '../engine/game_controller.dart';

class GameOverDialog extends StatelessWidget {
  final GameController controller;
  final VoidCallback onRestart;

  const GameOverDialog({
    super.key,
    required this.controller,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (controller.playTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (controller.playTime.toInt() % 60).toString().padLeft(2, '0');

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xEE090D12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF1744), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF1744),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF1744),
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'HULL BREACH DETECTED',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF5252),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The submersible has succumbed to the abyssal pressure and the creature of the trench.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x44000000),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Column(
                children: [
                  _buildStatRow('MAX DEPTH', '${controller.simulatedDepth.toInt()} M'),
                  const SizedBox(height: 6),
                  _buildStatRow(
                    'RELICS SALVAGED',
                    '${controller.world.submarine.collectedRelics} / ${controller.world.submarine.totalRelics}',
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow('SONAR PINGS EMITTED', '${controller.pingsCount}'),
                  const SizedBox(height: 6),
                  _buildStatRow('SCRAP SALVAGED', '+${controller.scrapEarnedThisRun} ⚙️'),
                  const SizedBox(height: 6),
                  _buildStatRow('TIME SURVIVED', '$minutes:$seconds'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'RETURN TO SURFACE BASE',
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

