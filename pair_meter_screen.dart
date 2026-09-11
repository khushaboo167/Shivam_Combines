import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';

class PairMeterScreen extends StatefulWidget {
  const PairMeterScreen({super.key});
  @override
  State<PairMeterScreen> createState() => _PairMeterScreenState();
}

class _PairMeterScreenState extends State<PairMeterScreen> {
  final _deviceId = TextEditingController(text: 'SHV-ESP-');
  final _serial = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _pair() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await FirebaseService.pairDevice(_deviceId.text.trim(), _serial.text.trim());
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair a Meter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _result != null ? _successView() : _formView(),
      ),
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('How a reading reaches your app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: const Text(
            'Meter → RS-485/Modbus → ESP32 → Shivam Cloud API → this app.\n'
            'Pairing tells the API which ESP32 and meter serial belong to your account.',
            style: TextStyle(fontSize: 12, color: C.muted, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        TextField(controller: _deviceId, decoration: const InputDecoration(labelText: 'ESP32 Device ID')),
        const SizedBox(height: 12),
        TextField(controller: _serial, decoration: const InputDecoration(labelText: 'Meter Serial')),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: C.danger, fontSize: 12)),
        ],
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: _loading ? null : _pair,
          child: Text(_loading ? 'Pairing...' : 'Pair meter'),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.successBg, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: C.teal),
              SizedBox(width: 10),
              Expanded(child: Text('Meter paired. Copy the key below into the ESP32 sketch.', style: TextStyle(fontSize: 12.5))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Device ID', style: TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.bold)),
        SelectableText(_result!['deviceId'], style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
        const SizedBox(height: 14),
        const Text('API Key — shown once, save it now', style: TextStyle(fontSize: 11, color: C.danger, fontWeight: FontWeight.bold)),
        SelectableText(_result!['apiKey'], style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    );
  }
}
