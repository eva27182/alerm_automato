import 'package:flutter/material.dart';

import '../models/alarm_preset.dart';
import '../services/alarm_setter.dart';

class EditorPage extends StatefulWidget {
  final AlarmPreset preset;
  const EditorPage({super.key, required this.preset});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final AlarmSetter _alarmSetter = AlarmSetter();
  late final TextEditingController _nameController;
  bool _isProcessing = false; // 処理中かどうかを管理するフラグ

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _applyAll() async {
    if (_isProcessing) return; // 処理中の二重実行を防止
    if (widget.preset.times.isEmpty) {
      _showSnackBar('時間が1つも設定されていません');
      return;
    }
    setState(() => _isProcessing = true); // ローディング開始

    try {
      await _alarmSetter.setAll(widget.preset.times);
      _showSnackBar('セット完了！');
    } catch (_) {
      _showSnackBar('アラームを設定できませんでした。時計アプリを確認してください。');
    } finally {
      // 失敗時もフラグを必ず戻す。戻さないとModalBarrierとcanPop無効で操作不能になる。
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.preset.times[index],
    );
    if (picked != null && mounted) {
      setState(() => widget.preset.times[index] = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 処理中は戻る操作（戻るボタン・戻るジェスチャー・AppBarの←）を無効化
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        appBar: AppBar(title: const Text('編集')),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'セット名',
                        border: OutlineInputBorder(),
                      ),
                      controller: _nameController,
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
                          title: Text(
                            time.format(context),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => setState(
                              () => widget.preset.times.removeAt(index),
                            ),
                          ),
                          onTap: () => _pickTime(index),
                        );
                      },
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
            ),
            // 処理中に最前面に表示するオーバーレイレイヤー
            if (_isProcessing) const _ProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(
                () => widget.preset.times.add(
                  const TimeOfDay(hour: 8, minute: 0),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('時間を追加'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _applyAll,
              icon: const Icon(Icons.alarm_on),
              label: const Text('一括設定'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // 下のUIへのタップを確実に遮断するバリア
        ModalBarrier(color: Colors.black54, dismissible: false),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'アラームを設定中...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
