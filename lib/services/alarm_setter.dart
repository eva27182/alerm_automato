import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import '../models/alarm_preset.dart';

/// OSの時計アプリへのアラーム一括登録を担当する。
class AlarmSetter {
  static const String _appPackage = 'com.example.alerm_automato';
  static const Duration _clockAppLaunchWait = Duration(milliseconds: 800);
  static const Duration _alarmRegisterWait = Duration(milliseconds: 600);

  /// 時計アプリを前面に出したまま全アラームを登録し、最後に自アプリへ戻る。
  /// 時計アプリが見つからない等で失敗した場合は例外を投げる（呼び出し側で通知）。
  Future<void> setAll(List<AlarmEntry> alarms) async {
    // 先に時計アプリのアラーム一覧を前面に出し、追加が終わるまで表示したままにする。
    // 以降のSET_ALARMは時計アプリの画面の上で処理されるため、
    // 自アプリとの行き来によるちらつきが発生しない。
    const showIntent = AndroidIntent(
      action: 'android.intent.action.SHOW_ALARMS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await showIntent.launch();
    await Future.delayed(_clockAppLaunchWait); // 時計アプリの起動待ち

    try {
      for (final alarm in alarms) {
        final intent = AndroidIntent(
          action: 'android.intent.action.SET_ALARM',
          flags: <int>[
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_ACTIVITY_NO_ANIMATION,
          ],
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.HOUR': alarm.time.hour,
            'android.intent.extra.alarm.MINUTES': alarm.time.minute,
            'android.intent.extra.alarm.SKIP_UI': true,
            // ラベルが空でもMESSAGEを渡す。渡さないと時計アプリが
            // 前回のラベルを引き継ぐ場合があるため、常に明示する。
            'android.intent.extra.alarm.MESSAGE': alarm.label,
          },
        );
        await intent.launch();
        await Future.delayed(_alarmRegisterWait); // 登録反映の待機
      }
    } finally {
      // 途中で失敗しても時計アプリの上に取り残さず、自アプリへ戻す。
      await _bringAppToFront();
    }
  }

  Future<void> _bringAppToFront() async {
    const backIntent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: _appPackage,
      componentName: '$_appPackage.MainActivity',
      flags: <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
        Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
        Flag.FLAG_ACTIVITY_NO_ANIMATION,
      ],
    );
    try {
      await backIntent.launch();
    } catch (_) {
      // 戻れなくてもユーザーが手動で戻れるため、元の失敗を優先して握りつぶす。
    }
  }
}
