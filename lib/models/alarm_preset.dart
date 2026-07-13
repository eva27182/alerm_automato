import 'package:flutter/material.dart';

// tree-shakingを維持するため、使用可能なアイコンは固定の定数マップに限定する。
const Map<String, IconData> kPresetIcons = {
  'alarm': Icons.alarm,
  'work': Icons.work,
};
const String kDefaultIconKey = 'alarm';

class AlarmPreset {
  String name;
  List<TimeOfDay> times;
  String iconKey;

  AlarmPreset({
    required this.name,
    required this.times,
    this.iconKey = kDefaultIconKey,
  });

  IconData get icon => kPresetIcons[iconKey] ?? kPresetIcons[kDefaultIconKey]!;

  Map<String, dynamic> toJson() => {
    'name': name,
    'times': times.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
    'icon': iconKey,
  };

  // 保存データは手動編集や旧バージョンで壊れている可能性があるため、
  // 型・範囲を検証し、不正な要素は捨てて読み込みを継続する。
  factory AlarmPreset.fromJson(Map<String, dynamic> json) {
    final times = <TimeOfDay>[];
    final rawTimes = json['times'];
    if (rawTimes is List) {
      for (final t in rawTimes) {
        if (t is! Map) continue;
        final hour = t['hour'];
        final minute = t['minute'];
        if (hour is int && minute is int && _isValidTime(hour, minute)) {
          times.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
    }
    final rawName = json['name'];
    final rawIcon = json['icon'];
    return AlarmPreset(
      name: rawName is String && rawName.isNotEmpty ? rawName : '無題のセット',
      times: times,
      // 旧バージョン（codePoint保存）のデータは既知のキーでないため既定アイコンにフォールバックする。
      iconKey: rawIcon is String && kPresetIcons.containsKey(rawIcon)
          ? rawIcon
          : kDefaultIconKey,
    );
  }

  static bool _isValidTime(int hour, int minute) =>
      hour >= 0 && hour < 24 && minute >= 0 && minute < 60;
}
