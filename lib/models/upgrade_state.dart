import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeState extends ChangeNotifier {
  int totalScrap = 0;
  int hullLevel = 0; // 0 to 5
  int reactorLevel = 0; // 0 to 5
  int dampenerLevel = 0; // 0 to 5
  int decoyLevel = 0; // 0 to 3

  static const int maxHullLevel = 5;
  static const int maxReactorLevel = 5;
  static const int maxDampenerLevel = 5;
  static const int maxDecoyLevel = 3;

  static const List<int> hullCosts = [50, 110, 190, 300, 450];
  static const List<int> reactorCosts = [50, 110, 190, 300, 450];
  static const List<int> dampenerCosts = [60, 130, 220, 340, 500];
  static const List<int> decoyCosts = [75, 160, 280];

  double get maxHull => 100.0 + hullLevel * 20.0; // 100 to 200 HP
  double get maxBattery => 100.0 + reactorLevel * 20.0; // 100 to 200 Energy
  double get passiveRechargeMultiplier => 1.0 + reactorLevel * 0.18; // +18% per tier
  double get noiseMultiplier => math.max(0.40, 1.0 - dampenerLevel * 0.12); // Up to -60% noise reduction
  int get startingDecoys => 2 + decoyLevel; // 2 to 5 decoys

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      totalScrap = prefs.getInt('total_scrap') ?? 100; // Give 100 scrap to start!
      hullLevel = (prefs.getInt('hull_level') ?? 0).clamp(0, maxHullLevel);
      reactorLevel = (prefs.getInt('reactor_level') ?? 0).clamp(0, maxReactorLevel);
      dampenerLevel = (prefs.getInt('dampener_level') ?? 0).clamp(0, maxDampenerLevel);
      decoyLevel = (prefs.getInt('decoy_level') ?? 0).clamp(0, maxDecoyLevel);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading upgrade state: $e');
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_scrap', totalScrap);
      await prefs.setInt('hull_level', hullLevel);
      await prefs.setInt('reactor_level', reactorLevel);
      await prefs.setInt('dampener_level', dampenerLevel);
      await prefs.setInt('decoy_level', decoyLevel);
    } catch (e) {
      debugPrint('Error saving upgrade state: $e');
    }
  }

  void addScrap(int amount) {
    totalScrap += amount;
    save();
    notifyListeners();
  }

  bool upgradeHull() {
    if (hullLevel < maxHullLevel) {
      final cost = hullCosts[hullLevel];
      if (totalScrap >= cost) {
        totalScrap -= cost;
        hullLevel++;
        save();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool upgradeReactor() {
    if (reactorLevel < maxReactorLevel) {
      final cost = reactorCosts[reactorLevel];
      if (totalScrap >= cost) {
        totalScrap -= cost;
        reactorLevel++;
        save();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool upgradeDampener() {
    if (dampenerLevel < maxDampenerLevel) {
      final cost = dampenerCosts[dampenerLevel];
      if (totalScrap >= cost) {
        totalScrap -= cost;
        dampenerLevel++;
        save();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool upgradeDecoys() {
    if (decoyLevel < maxDecoyLevel) {
      final cost = decoyCosts[decoyLevel];
      if (totalScrap >= cost) {
        totalScrap -= cost;
        decoyLevel++;
        save();
        notifyListeners();
        return true;
      }
    }
    return false;
  }
}

