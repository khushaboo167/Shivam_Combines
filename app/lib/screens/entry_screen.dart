import 'package:flutter/material.dart';
import '../theme.dart';
import 'power/power_login_screen.dart';
import 'service/service_login_screen.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.bolt, color: C.black, size: 32),
              ),
              const SizedBox(height: 14),
              const Text('SHIVAM',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Text('COMBINES',
                  style: TextStyle(color: C.teal, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('POWERING CONNECTIONS, EMPOWERING FUTURES',
                  style: TextStyle(color: Color(0xFF8A8F94), fontSize: 9, letterSpacing: 1.2)),
              const Spacer(),
              const Text('What do you need today?',
                  style: TextStyle(color: Color(0xFFB8BCC0), fontSize: 14)),
              const SizedBox(height: 20),
              _chooserTile(
                context,
                icon: Icons.flash_on,
                iconColor: C.gold,
                title: 'Power Monitor',
                subtitle: 'View your live meter readings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PowerLoginScreen())),
              ),
              const SizedBox(height: 12),
              _chooserTile(
                context,
                icon: Icons.build_outlined,
                iconColor: C.teal,
                title: 'Service',
                subtitle: 'Raise or track a complaint',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceLoginScreen())),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooserTile(BuildContext context,
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: C.charcoal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2B2E)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF8A8F94), fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF565A5F)),
          ],
        ),
      ),
    );
  }
}
