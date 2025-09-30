import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ticket_storage.dart';
import 'intro_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clearing = false;
  bool _signingOut = false;

  Future<void> _clearTickets() async {
    setState(() => _clearing = true);
    try {
      await TicketStorage.instance.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All tickets cleared on this device.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OnBoardingPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Account'),
          _tile(
            icon: Icons.logout,
            label: 'Sign Out',
            trailing: _signingOut ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right, color: Colors.white38),
            danger: true,
            onTap: _signingOut ? null : _signOut,
          ),
          const SizedBox(height: 26),
          _sectionTitle('Tickets'),
          _tile(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear All Tickets (local)',
            trailing: _clearing ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _clearing ? null : _clearTickets,
          ),
          const SizedBox(height: 26),
          _sectionTitle('Preferences'),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            activeColor: Colors.greenAccent.shade400,
            title: const Text('Notifications (placeholder)', style: TextStyle(color: Colors.white)),
          ),
          SwitchListTile(
            value: false,
            onChanged: (_) {},
            activeColor: Colors.greenAccent.shade400,
            title: const Text('Dark Mode (Always On)', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 50),
          const Center(
            child: Text('v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _tile({required IconData icon, required String label, VoidCallback? onTap, Widget? trailing, bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? const Color(0xFFFF5DA2) : Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: TextStyle(color: danger ? const Color(0xFFFF5DA2) : Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}
