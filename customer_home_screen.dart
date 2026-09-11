import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';
import 'submit_complaint_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: FirebaseService.signOut)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.gold,
        foregroundColor: C.black,
        icon: const Icon(Icons.add),
        label: const Text('New complaint'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitComplaintScreen())),
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: FirebaseService.myComplaints(uid),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!;
          if (docs.isEmpty) {
            return const Center(child: Text('No requests yet', style: TextStyle(color: C.muted)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: cardDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(d.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    _statusBadge(d.status),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'new': C.gold,
      'in_progress': C.teal,
      'resolved': const Color(0xFF6E747A),
    };
    final labels = {'new': 'New', 'in_progress': 'In progress', 'resolved': 'Resolved'};
    final color = colors[status] ?? C.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(labels[status] ?? status, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }
}
