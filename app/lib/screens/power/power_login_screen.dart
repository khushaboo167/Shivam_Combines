import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';
import 'live_readings_screen.dart';

class PowerLoginScreen extends StatefulWidget {
  const PowerLoginScreen({super.key});
  @override
  State<PowerLoginScreen> createState() => _PowerLoginScreenState();
}

class _PowerLoginScreenState extends State<PowerLoginScreen> {
  final _email = TextEditingController(text: FirebaseService.demoMode ? 'power@demo.com' : '');
  final _pass = TextEditingController(text: FirebaseService.demoMode ? 'Demo1234' : '');
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) { setState(() => _error = 'Enter a valid email address.'); return; }
    if (_pass.text.length < 6) { setState(() => _error = 'Password must be at least 6 characters.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        await FirebaseService.signUp(_email.text.trim(), _pass.text.trim());
      } else {
        await FirebaseService.signIn(_email.text.trim(), _pass.text.trim());
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LiveReadingsScreen()));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.black,
      appBar: AppBar(backgroundColor: C.black, elevation: 0, title: const Text('Power Monitor')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text('Meter owner login',
                style: TextStyle(color: C.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: C.danger, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Please wait...' : (_isSignUp ? 'Create account' : 'Log in')),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp ? 'Already have an account? Log in' : "New meter owner? Create an account",
                style: const TextStyle(color: Color(0xFF8A8F94), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
