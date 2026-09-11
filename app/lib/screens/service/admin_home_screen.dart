import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';
import 'request_detail_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Overview'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: FirebaseService.signOut)],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: FirebaseService.allComplaints(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!;
          final open = docs.where((d) => d.status != 'resolved').length;
          final newToday = docs.where((d) {
            final now = DateTime.now();
            final dt = d.createdAt;
            return dt.year == now.year && dt.month == now.month && dt.day == now.day;
          }).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _stat('Open', open.toString(), C.gold),
                  const SizedBox(width: 10),
                  _stat('Total', docs.length.toString(), C.teal),
                  const SizedBox(width: 10),
                  _stat('New today', newToday.toString(), C.ink),
                ],
              ),
              const SizedBox(height: 20),
              const Text('All Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              ...docs.map((doc) {
                final d = doc;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: cardDecoration(),
                  child: ListTile(
                    title: Text(d.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${d.name} · ${d.phone}', style: const TextStyle(fontSize: 11.5, color: C.muted)),
                    trailing: Text(d.status, style: const TextStyle(fontSize: 11)),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => RequestDetailScreen(complaintId: d.id, data: d))),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: cardDecoration(),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10.5, color: C.muted)),
          ],
        ),
      ),
    );
  }
}
