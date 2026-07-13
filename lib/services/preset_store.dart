import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_preset.dart';

/// プリセットの永続化を担当する。読み書きの失敗は呼び出し側に例外を漏らさない。
class PresetStore {
  static const String _storageKey = 'alarm_presets';

  /// 保存データがない・壊れている場合は null を返す（呼び出し側で既定値にフォールバック）。
  Future<List<AlarmPreset>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data == null) return null;
      final decoded = json.decode(data);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AlarmPreset.fromJson)
          .toList();
    } catch (_) {
      // 壊れたデータで起動不能になるより、既定値で立ち上がる方を優先する。
      return null;
    }
  }

  /// 保存に成功したら true。
  Future<bool> save(List<AlarmPreset> presets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(presets.map((p) => p.toJson()).toList());
      return await prefs.setString(_storageKey, encoded);
    } catch (_) {
      return false;
    }
  }
}
