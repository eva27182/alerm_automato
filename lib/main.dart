import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      textTheme: GoogleFonts.notoSansJpTextTheme(),
    ),
    home: const PresetGridPage(),
  ));
}

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

  AlarmPreset({required this.name, required this.times, this.iconKey = kDefaultIconKey});

  IconData get icon => kPresetIcons[iconKey] ?? kPresetIcons[kDefaultIconKey]!;

  Map<String, dynamic> toJson() => {
    'name': name,
    'times': times.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
    'icon': iconKey,
  };

  factory AlarmPreset.fromJson(Map<String, dynamic> json) {
    var timesList = (json['times'] as List)
        .map((t) => TimeOfDay(hour: t['hour'], minute: t['minute']))
        .toList();
    final rawIcon = json['icon'];
    return AlarmPreset(
      name: json['name'],
      times: timesList,
      // 旧バージョン（codePoint保存）のデータは既知のキーでないため既定アイコンにフォールバックする。
      iconKey: rawIcon is String && kPresetIcons.containsKey(rawIcon) ? rawIcon : kDefaultIconKey,
    );
  }
}

class PresetGridPage extends StatefulWidget {
  const PresetGridPage({super.key});

  @override
  State<PresetGridPage> createState() => _PresetGridPageState();
}

class _PresetGridPageState extends State<PresetGridPage> {
  List<AlarmPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('alarm_presets');
    if (data != null) {
      final List decoded = json.decode(data);
      setState(() {
        _presets = decoded.map((item) => AlarmPreset.fromJson(item)).toList();
      });
    } else {
      setState(() {
        _presets = [
          AlarmPreset(name: '平日用', times: [const TimeOfDay(hour: 7, minute: 0)], iconKey: 'work'),
        ];
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_presets.map((p) => p.toJson()).toList());
    await prefs.setString('alarm_presets', encoded);
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除'),
        content: Text('「${_presets[index].name}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              setState(() => _presets.removeAt(index));
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('爆速アラーム'), centerTitle: true),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: _presets.length + 1,
          itemBuilder: (context, index) {
            if (index == _presets.length) return _buildAddCard();
            return _buildPresetCard(_presets[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildPresetCard(AlarmPreset preset, int index) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => EditorPage(preset: preset)));
        _saveData();
        setState(() {});
      },
      onLongPress: () => _confirmDelete(index),
      child: Card(
        elevation: 4,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(preset.icon, size: 50, color: Colors.blue),
                  const SizedBox(height: 10),
                  Text(preset.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${preset.times.length} 個設定中'),
                ],
              ),
            ),
            const Positioned(top: 8, right: 8, child: Icon(Icons.delete_outline, size: 18, color: Colors.black26)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    return InkWell(
      onTap: () {
        setState(() => _presets.add(AlarmPreset(name: '新規セット', times: [const TimeOfDay(hour: 8, minute: 0)])));
        _saveData();
      },
      child: Card(color: Colors.grey[100], child: const Icon(Icons.add, size: 50, color: Colors.grey)),
    );
  }
}

class EditorPage extends StatefulWidget {
  final AlarmPreset preset;
  const EditorPage({super.key, required this.preset});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  bool _isProcessing = false; // ★ 処理中かどうかを管理するフラグ

  Future<void> _applyAll() async {
    setState(() => _isProcessing = true); // ローディング開始

    for (var time in widget.preset.times) {
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        // 画面切り替えアニメーションを消し、時計アプリを履歴に残さない
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_ACTIVITY_NO_ANIMATION,
          Flag.FLAG_ACTIVITY_NO_HISTORY,
        ],
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': time.hour,
          'android.intent.extra.alarm.MINUTES': time.minute,
          'android.intent.extra.alarm.SKIP_UI': true,
        },
      );
      await intent.launch();
      await Future.delayed(const Duration(milliseconds: 600)); // チラつき抑制のための待機
    }

    // 時計アプリが前面に残るため、自アプリを前面に呼び戻す
    const backIntent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: 'com.example.alerm_automato',
      componentName: 'com.example.alerm_automato.MainActivity',
      flags: <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
        Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
        Flag.FLAG_ACTIVITY_NO_ANIMATION,
      ],
    );
    await backIntent.launch();

    if (mounted) {
      setState(() => _isProcessing = false); // ローディング終了
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('セット完了！')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('編集')),
      // ★ Stack を使って UI レイヤーを重ねる
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'セット名', border: OutlineInputBorder()),
                    controller: TextEditingController(text: widget.preset.name),
                    onChanged: (val) => widget.preset.name = val,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.preset.times.length,
                    itemBuilder: (context, index) {
                      final time = widget.preset.times[index];
                      return ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(time.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () => setState(() => widget.preset.times.removeAt(index)),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: time);
                          if (picked != null) setState(() => widget.preset.times[index] = picked);
                        },
                      );
                    },
                  ),
                ),
                // 下部ボタン
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => widget.preset.times.add(const TimeOfDay(hour: 8, minute: 0))), icon: const Icon(Icons.add), label: const Text('時間を追加'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(onPressed: _applyAll, icon: const Icon(Icons.alarm_on), label: const Text('一括設定'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
                    ],
                  ),
                )
              ],
            ),
          ),
          // ★ 処理中に最前面に表示するオーバーレイレイヤー
          if (_isProcessing)
            Container(
              color: Colors.black54, // 半透明の黒
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text('アラームを設定中...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}