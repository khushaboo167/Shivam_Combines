import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final String complaintId;
  final Complaint data;
  const RequestDetailScreen({super.key, required this.complaintId, required this.data});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.data.status;
  }

  Future<void> _setStatus(String s) async {
    await FirebaseService.updateComplaintStatus(widget.complaintId, s);
    setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Scaffold(
      appBar: AppBar(title: Text(widget.complaintId)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text('Customer details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Name', d.name),
                  _row('Phone', d.phone),
                  _row('Meter / Account', d.meterId),
                  _row('Address', d.address),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(14), decoration: cardDecoration(), child: Text(d.description)),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _statusChip('new', 'New'),
                _statusChip('in_progress', 'In progress'),
                _statusChip('resolved', 'Resolved'),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call),
              label: Text('Call ${d.phone.isEmpty ? 'customer' : d.phone}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: C.muted, fontSize: 12)),
          Text(value ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final on = _status == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: on ? C.black : C.muted)),
      selected: on,
      selectedColor: C.gold,
      backgroundColor: Colors.white,
      onSelected: (_) => _setStatus(value),
    );
  }
}
