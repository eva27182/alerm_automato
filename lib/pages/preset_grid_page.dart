import 'package:flutter/material.dart';

import '../models/alarm_preset.dart';
import '../services/preset_store.dart';
import 'editor_page.dart';

class PresetGridPage extends StatefulWidget {
  const PresetGridPage({super.key});

  @override
  State<PresetGridPage> createState() => _PresetGridPageState();
}

class _PresetGridPageState extends State<PresetGridPage> {
  final PresetStore _store = PresetStore();
  List<AlarmPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loaded = await _store.load();
    if (!mounted) return;
    setState(() {
      _presets =
          loaded ??
          [
            AlarmPreset(
              name: '平日用',
              times: [const TimeOfDay(hour: 7, minute: 0)],
              iconKey: 'work',
            ),
          ];
    });
  }

  Future<void> _saveData() async {
    final saved = await _store.save(_presets);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('削除'),
        content: Text('「${_presets[index].name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _presets.removeAt(index));
              _saveData();
              Navigator.pop(dialogContext);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(AlarmPreset preset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorPage(preset: preset)),
    );
    if (!mounted) return;
    setState(() {});
    await _saveData();
  }

  void _addPreset() {
    setState(
      () => _presets.add(
        AlarmPreset(
          name: '新規セット',
          times: [const TimeOfDay(hour: 8, minute: 0)],
        ),
      ),
    );
    _saveData();
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
      onTap: () => _openEditor(preset),
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
                  Text(
                    preset.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${preset.times.length} 個設定中'),
                ],
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    return InkWell(
      onTap: _addPreset,
      child: Card(
        color: Colors.grey[100],
        child: const Icon(Icons.add, size: 50, color: Colors.grey),
      ),
    );
  }
}
