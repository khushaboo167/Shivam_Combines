import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});
  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _meterId = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Power off';
  bool _loading = false;
  String? _error;
  final _categories = ['Power off', 'Meter fault', 'Wiring', 'Billing', 'Other'];

  Future<void> _submit() async {
    if (_meterId.text.trim().isEmpty || _address.text.trim().isEmpty || _description.text.trim().isEmpty) {
      setState(() => _error = 'Please fill Meter/Account ID, Address and Issue description.');
      return;
    }
    final user = FirebaseService.currentUser;
    if (user == null) {
      setState(() => _error = 'Your session has expired. Please log in again.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await FirebaseService.getUserProfile(user.uid);
      if (profile == null) throw Exception('Customer profile not found.');
      await FirebaseService.submitComplaint({
        'customerId': user.uid,
        'name': profile.name,
        'phone': profile.phone,
        'meterId': _meterId.text.trim(),
        'address': _address.text.trim(),
        'category': _category,
        'description': _description.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted successfully.')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _meterId, decoration: const InputDecoration(labelText: 'Meter / Account ID')),
          const SizedBox(height: 12),
          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 16),
          const Text('Issue type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: C.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) {
            final on = c == _category;
            return ChoiceChip(label: Text(c, style: TextStyle(fontSize: 12, color: on ? C.black : C.muted)), selected: on, selectedColor: C.gold, backgroundColor: Colors.white, onSelected: (_) => setState(() => _category = c));
          }).toList()),
          const SizedBox(height: 16),
          TextField(controller: _description, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe the issue')),
          if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: C.danger, fontSize: 12))],
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Sending...' : 'Submit complaint')),
        ]),
      ),
    );
  }
}
