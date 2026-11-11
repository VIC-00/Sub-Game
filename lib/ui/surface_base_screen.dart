import 'package:flutter/material.dart';
import '../audio/sound_synthesizer.dart';
import '../models/upgrade_state.dart';

class SurfaceBaseScreen extends StatefulWidget {
  final UpgradeState upgradeState;
  final VoidCallback onLaunchExpedition;
  final int lastRunScrap;
  final bool lastRunWon;

  const SurfaceBaseScreen({
    super.key,
    required this.upgradeState,
    required this.onLaunchExpedition,
    this.lastRunScrap = 0,
    this.lastRunWon = false,
  });

  @override
  State<SurfaceBaseScreen> createState() => _SurfaceBaseScreenState();
}

class _SurfaceBaseScreenState extends State<SurfaceBaseScreen> {
  @override
  Widget build(BuildContext context) {
    final up = widget.upgradeState;

    return Scaffold(
      backgroundColor: const Color(0xFF060B10),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xDD09151E),
                border: Border(bottom: BorderSide(color: Color(0x4400FFC8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'HADAL COMMAND BASE',
                        style: TextStyle(
                          color: Color(0xFF00FFC8),
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'SUBMERSIBLE RETROFIT & UPGRADE TERMINAL',
                        style: TextStyle(
                          color: Color(0xFF90A4AE),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),

                  // Scrap Balance Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFB74D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33FFB74D), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.settings, color: Color(0xFFFFB74D), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${up.totalScrap} SCRAP',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Previous Run Debrief (if applicable)
                  if (widget.lastRunScrap > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.lastRunWon ? const Color(0x2200FFC8) : const Color(0x22FF1744),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.lastRunWon ? const Color(0xFF00FFC8) : const Color(0xFFFF5252),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.lastRunWon ? Icons.check_circle : Icons.warning,
                            color: widget.lastRunWon ? const Color(0xFF00FFC8) : const Color(0xFFFF5252),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.lastRunWon ? 'EXPEDITION EXTRACTED' : 'SUBMERSIBLE LOST TO ABYSS',
                                  style: TextStyle(
                                    color: widget.lastRunWon ? const Color(0xFF00FFC8) : const Color(0xFFFF5252),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Salvaged +${widget.lastRunScrap} Scrap from the deep trench.',
                                  style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Upgrade Cards
                  _buildUpgradeCard(
                    title: 'REINFORCED TITANIUM HULL',
                    subtitle: 'Increases hull structural integrity against rock collisions & monster attacks.',
                    currentLevel: up.hullLevel,
                    maxLevel: UpgradeState.maxHullLevel,
                    currentStat: '${up.maxHull.toInt()} HP',
                    nextStat: up.hullLevel < UpgradeState.maxHullLevel ? '${(up.maxHull + 20).toInt()} HP' : 'MAXED',
                    cost: up.hullLevel < UpgradeState.maxHullLevel ? UpgradeState.hullCosts[up.hullLevel] : null,
                    icon: Icons.shield,
                    accentColor: const Color(0xFF00FFC8),
                    onUpgrade: () {
                      if (up.upgradeHull()) {
                        SoundSynthesizer.playRelicCollected();
                        setState(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildUpgradeCard(
                    title: 'HIGH-CAPACITY REACTOR',
                    subtitle: 'Expands energy reserves and boosts thermoelectric passive recharge rate.',
                    currentLevel: up.reactorLevel,
                    maxLevel: UpgradeState.maxReactorLevel,
                    currentStat: '${up.maxBattery.toInt()} ⚡ (+${((up.passiveRechargeMultiplier - 1.0) * 100).toInt()}% Regen)',
                    nextStat: up.reactorLevel < UpgradeState.maxReactorLevel ? '${(up.maxBattery + 20).toInt()} ⚡ (+${((up.passiveRechargeMultiplier - 1.0 + 0.18) * 100).toInt()}%)' : 'MAXED',
                    cost: up.reactorLevel < UpgradeState.maxReactorLevel ? UpgradeState.reactorCosts[up.reactorLevel] : null,
                    icon: Icons.bolt,
                    accentColor: const Color(0xFF00E5FF),
                    onUpgrade: () {
                      if (up.upgradeReactor()) {
                        SoundSynthesizer.playRelicCollected();
                        setState(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildUpgradeCard(
                    title: 'ACOUSTIC DAMPENER',
                    subtitle: 'Suppresses thruster vibration and ping loudness, reducing monster hearing range.',
                    currentLevel: up.dampenerLevel,
                    maxLevel: UpgradeState.maxDampenerLevel,
                    currentStat: '-${((1.0 - up.noiseMultiplier) * 100).toInt()}% Noise',
                    nextStat: up.dampenerLevel < UpgradeState.maxDampenerLevel ? '-${((1.0 - up.noiseMultiplier + 0.12) * 100).toInt()}% Noise' : 'MAXED',
                    cost: up.dampenerLevel < UpgradeState.maxDampenerLevel ? UpgradeState.dampenerCosts[up.dampenerLevel] : null,
                    icon: Icons.hearing,
                    accentColor: const Color(0xFFB388FF),
                    onUpgrade: () {
                      if (up.upgradeDampener()) {
                        SoundSynthesizer.playRelicCollected();
                        setState(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildUpgradeCard(
                    title: 'DECOY SILO EXPANSION',
                    subtitle: 'Provides additional deployable acoustic decoys at the start of each dive.',
                    currentLevel: up.decoyLevel,
                    maxLevel: UpgradeState.maxDecoyLevel,
                    currentStat: '${up.startingDecoys} Decoys',
                    nextStat: up.decoyLevel < UpgradeState.maxDecoyLevel ? '${up.startingDecoys + 1} Decoys' : 'MAXED',
                    cost: up.decoyLevel < UpgradeState.maxDecoyLevel ? UpgradeState.decoyCosts[up.decoyLevel] : null,
                    icon: Icons.flare,
                    accentColor: const Color(0xFFFFB74D),
                    onUpgrade: () {
                      if (up.upgradeDecoys()) {
                        SoundSynthesizer.playRelicCollected();
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),

            // Launch Expedition Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xDD09151E),
                border: Border(top: BorderSide(color: Color(0x3300FFC8))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    SoundSynthesizer.playLoudPing();
                    widget.onLaunchExpedition();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFC8),
                    foregroundColor: Colors.black,
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sailing, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'LAUNCH EXPEDITION (DIVE INTO TRENCH)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required String subtitle,
    required int currentLevel,
    required int maxLevel,
    required String currentStat,
    required String nextStat,
    required int? cost,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onUpgrade,
  }) {
    final bool isMaxed = currentLevel >= maxLevel;
    final bool canAfford = !isMaxed && (widget.upgradeState.totalScrap >= (cost ?? 0));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEE0D1A24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 10, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tiers Progress Indicators
          Row(
            children: [
              for (int i = 0; i < maxLevel; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < currentLevel ? accentColor : const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Stat & Upgrade Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATUS: $currentStat' + (!isMaxed ? ' ➔ $nextStat' : ''),
                style: const TextStyle(
                  color: Color(0xFFB0BEC5),
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              ElevatedButton(
                onPressed: canAfford ? onUpgrade : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? accentColor : const Color(0x44263238),
                  foregroundColor: canAfford ? Colors.black : Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(
                  isMaxed ? 'MAX LEVEL' : 'UPGRADE (${cost}⚙️)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
