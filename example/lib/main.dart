import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mic_router/mic_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = MicRouter();

  Map<String, dynamic> _micInfo = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMicInfo();
  }

  Future<void> _loadMicInfo() async {
    final info = await _plugin.getMicInfo();
    if (!mounted) return;
    setState(() {
      _micInfo = info;
    });
  }

  Future<void> _selectMic(String id) async {
    setState(() => _loading = true);

    final stopwatch = Stopwatch()..start();

    await _plugin.setMic(id);
    final updated = await _plugin.getMicInfo();

    final remaining = 1000 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    setState(() {
      _micInfo = updated;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputs = (_micInfo['availableInputs'] ?? []) as List;
    final current = _micInfo['currentInput'];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mic Router')),
        body: Stack(
          children: [
            ListView(
              children: inputs.map((mic) {
                final isSelected = current != null && mic['id'] == current['id'];

                return ListTile(
                  leading: Icon(
                    mic['type'].toString().contains('Bluetooth')
                        ? Icons.bluetooth
                        : mic['type'].toString().contains('Headset')
                        ? Icons.headphones
                        : Icons.mic,
                  ),
                  title: Text(mic['name']),
                  subtitle: Text('${mic['type']}\n${mic['id']}'),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: isSelected ? null : () => _selectMic(mic['id']),
                );
              }).toList(),
            ),

            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
