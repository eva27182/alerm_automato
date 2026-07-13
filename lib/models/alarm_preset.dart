import 'package:flutter/material.dart';

// tree-shakingを維持するため、使用可能なアイコンは固定の定数マップに限定する。
const Map<String, IconData> kPresetIcons = {
  'alarm': Icons.alarm,
  'work': Icons.work,
};
const String kDefaultIconKey = 'alarm';

/// 1件のアラーム（時刻＋任意のラベル）。
class AlarmEntry {
  TimeOfDay time;
  String label;

  AlarmEntry({required this.time, this.label = ''});

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'label': label,
  };
}

class AlarmPreset {
  String name;
  List<AlarmEntry> alarms;
  String iconKey;

  AlarmPreset({
    required this.name,
    required this.alarms,
    this.iconKey = kDefaultIconKey,
  });

  IconData get icon => kPresetIcons[iconKey] ?? kPresetIcons[kDefaultIconKey]!;

  // AlarmEntry は可変なので、リストごと要素も複製して元プリセットと共有されないようにする。
  AlarmPreset duplicate() => AlarmPreset(
    name: '$nameのコピー',
    alarms: alarms
        .map((a) => AlarmEntry(time: a.time, label: a.label))
        .toList(),
    iconKey: iconKey,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'times': alarms.map((a) => a.toJson()).toList(),
    'icon': iconKey,
  };

  // 保存データは手動編集や旧バージョンで壊れている可能性があるため、
  // 型・範囲を検証し、不正な要素は捨てて読み込みを継続する。
  factory AlarmPreset.fromJson(Map<String, dynamic> json) {
    final alarms = <AlarmEntry>[];
    final rawTimes = json['times'];
    if (rawTimes is List) {
      for (final t in rawTimes) {
        if (t is! Map) continue;
        final hour = t['hour'];
        final minute = t['minute'];
        if (hour is int && minute is int && _isValidTime(hour, minute)) {
          // ラベルは旧バージョンのデータには無いため、無ければ空文字にフォールバックする。
          final rawLabel = t['label'];
          alarms.add(AlarmEntry(
            time: TimeOfDay(hour: hour, minute: minute),
            label: rawLabel is String ? rawLabel : '',
          ));
        }
      }
    }
    final rawName = json['name'];
    final rawIcon = json['icon'];
    return AlarmPreset(
      name: rawName is String && rawName.isNotEmpty ? rawName : '無題のセット',
      alarms: alarms,
      // 旧バージョン（codePoint保存）のデータは既知のキーでないため既定アイコンにフォールバックする。
      iconKey: rawIcon is String && kPresetIcons.containsKey(rawIcon)
          ? rawIcon
          : kDefaultIconKey,
    );
  }

  static bool _isValidTime(int hour, int minute) =>
      hour >= 0 && hour < 24 && minute >= 0 && minute < 60;
}
