import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';
import 'pair_meter_screen.dart';

class LiveReadingsScreen extends StatelessWidget {
  const LiveReadingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Readings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PairMeterScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Device>>(
        stream: FirebaseService.myDevices(uid),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!;
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_off, color: C.muted, size: 40),
                    const SizedBox(height: 10),
                    const Text('No meters paired yet', style: TextStyle(color: C.muted)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PairMeterScreen())),
                      child: const Text('Pair a meter'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) => _DeviceCard(deviceId: docs[i].id, data: docs[i]),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String deviceId;
  final Device data;
  const _DeviceCard({required this.deviceId, required this.data});

  bool get _isOnline {
    final lastSeen = data.lastSeen;
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen).inMinutes < 12;
  }

  @override
  Widget build(BuildContext context) {
    final reading = data.lastReading;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(deviceId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isOnline ? C.successBg : const Color(0xFFFBEAE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOnline ? 'Live' : 'Offline',
                  style: TextStyle(
                      color: _isOnline ? C.teal : C.danger, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Meter: ${data.meterSerial}', style: const TextStyle(color: C.muted, fontSize: 11.5)),
          const SizedBox(height: 14),
          if (reading == null)
            const Text('Waiting for first reading...', style: TextStyle(color: C.muted, fontSize: 12))
          else
            Row(
              children: [
                Expanded(child: _readout('VLL avg', reading.vllAvg, 'V')),
                Expanded(child: _readout('Current avg', reading.currentAvg, 'A')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _readout(String label, dynamic value, String unit) {
    final v = value.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$v $unit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.ink)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: C.muted)),
      ],
    );
  }
}
