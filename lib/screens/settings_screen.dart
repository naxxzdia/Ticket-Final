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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF4081)),
          splashRadius: 24,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: .3),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('Account'),
          _tile(
            icon: Icons.logout,
            label: 'Sign Out',
            trailing: _signingOut
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.chevron_right, color: Colors.white38),
            danger: true,
            onTap: _signingOut ? null : _signOut,
          ),
          const SizedBox(height: 28),
          _sectionTitle('Tickets'),
          _tile(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear All Tickets (Local)',
            trailing: _clearing
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : null,
            onTap: _clearing ? null : _clearTickets,
          ),
          const SizedBox(height: 28),
          _sectionTitle('Preferences'),
          _switchTile(
            value: true,
            label: 'Notifications (placeholder)',
            onChanged: (_) {},
          ),
          _switchTile(
            value: false,
            label: 'Dark Mode (Always On)',
            onChanged: (_) {},
          ),
          const SizedBox(height: 60),
          const Center(
            child: Text('v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: .5)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
        child: Row(
          children: [
            Container(width: 4, height: 14, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF4081), Color(0xFF673AB7)]), borderRadius: BorderRadius.all(Radius.circular(2)))),
            const SizedBox(width: 10),
            Text(text.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          ],
        ),
      );

  Widget _tile({required IconData icon, required String label, VoidCallback? onTap, Widget? trailing, bool danger = false}) {
    const accent = Color(0xFFFF4081);
    const dangerColor = Color(0xFFE75480);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1E3F).withOpacity(.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? dangerColor : accent, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: danger ? dangerColor : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: .2,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({required bool value, required String label, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E3F).withOpacity(.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        inactiveThumbColor: const Color(0xFF4A3B6B),
        inactiveTrackColor: const Color(0xFF241832),
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFFF4081),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
      ),
    );
  }
}
