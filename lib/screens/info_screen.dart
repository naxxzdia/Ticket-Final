import 'package:flutter/material.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});
  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String? _version;
  String? _build;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    // Fallback static version (could integrate package_info_plus later)
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() {
      _version = '0.3.0';
      _build = '300';
    });
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('App Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          _sectionHeader('OVERVIEW'),
          _card(child: const Text('This app demonstrates a modern ticket purchase & e‑ticket experience with a 3‑step checkout, dynamic palette ticket, and local ticket persistence.')),
          const SizedBox(height: 20),
          _sectionHeader('VERSION'),
          _kv('Version', _version ?? '…'),
          _kv('Build', _build ?? '…'),
          const SizedBox(height: 20),
          _sectionHeader('DATA & STORAGE'),
          _card(child: const Text('Tickets are stored locally using SharedPreferences only. No cloud sync is active for purchased tickets in this build.')),          
          const SizedBox(height: 20),
          _sectionHeader('PRIVACY'),
          _card(child: const Text('Authentication and avatar uploads go through Firebase Auth & Storage. Other personal data (location, display name) is stored locally. No analytics collection is implemented.')),
          const SizedBox(height: 20),
          _sectionHeader('SUPPORT'),
          _card(child: const Text('For issues or feature ideas, integrate a feedback form or link to a repository issue tracker.')),          
          const SizedBox(height: 20),
          _sectionHeader('CHANGELOG (SAMPLE)'),
          _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ChangelogItem(title: '0.3.0', points: ['Added gradient theming overhaul', 'Ticket list animations & styling refinements']),
              SizedBox(height: 10),
              _ChangelogItem(title: '0.2.0', points: ['3-step checkout flow', 'E‑Ticket palette extraction + share']),
              SizedBox(height: 10),
              _ChangelogItem(title: '0.1.0', points: ['Initial prototype: events list, basic purchase, local persistence']),
            ],
          )),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF4081), Color(0xFF673AB7)]), borderRadius: BorderRadius.all(Radius.circular(2)))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return _card(
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF242129),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3055).withOpacity(.30)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white70, fontSize: 13.2, height: 1.36),
        child: child,
      ),
    );
  }
}

class _ChangelogItem extends StatelessWidget {
  const _ChangelogItem({required this.title, required this.points});
  final String title;
  final List<String> points;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ...points.map((p) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Expanded(child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
      ],
    );
  }
}
