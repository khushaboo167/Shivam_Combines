import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/firebase_service.dart';
import 'customer_home_screen.dart';
import 'admin_home_screen.dart';

class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({super.key});
  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController(text: FirebaseService.demoMode ? 'customer@demo.com' : '');
  final _pass = TextEditingController(text: FirebaseService.demoMode ? 'Demo1234' : '');
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_isSignUp && (_name.text.trim().isEmpty || _phone.text.trim().isEmpty)) {
      setState(() => _error = 'Name and phone are required.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        final cred = await FirebaseService.signUp(_email.text.trim(), _pass.text.trim());
        await FirebaseService.createUserProfile(
          uid: cred.uid,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
        );
      } else {
        await FirebaseService.signIn(_email.text.trim(), _pass.text.trim());
      }
      await _routeAfterLogin();
    } catch (e) {
      if (mounted) setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanError(Object e) {
    final text = e.toString();
    if (text.contains('wrong-password') || text.contains('invalid-credential')) return 'Incorrect email or password.';
    if (text.contains('email-already-in-use')) return 'An account with this email already exists.';
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> _routeAfterLogin() async {
    final user = FirebaseService.currentUser;
    if (user == null) throw Exception('Login did not create a user session.');
    final profile = await FirebaseService.getUserProfile(user.uid);
    final isAdmin = profile?.isAdmin ?? user.isAdmin;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => isAdmin ? const AdminHomeScreen() : const CustomerHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.black,
      appBar: AppBar(backgroundColor: C.black, elevation: 0, title: const Text('Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (FirebaseService.demoMode) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: C.gold.withOpacity(.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: C.gold.withOpacity(.4))),
                child: const Text('DEMO MODE\nCustomer: customer@demo.com / Demo1234\nAdmin: admin@demo.com / Demo1234', style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
              ),
              const SizedBox(height: 18),
            ],
            if (_isSignUp) ...[
              TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: _phone, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
            ],
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _pass, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Password')),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: C.danger, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Please wait...' : (_isSignUp ? 'Create customer account' : 'Log in'))),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
              child: Text(_isSignUp ? 'Already have an account? Log in' : 'New customer? Create an account', style: const TextStyle(color: Color(0xFF8A8F94), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
