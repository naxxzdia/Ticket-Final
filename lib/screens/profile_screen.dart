import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ticket_storage.dart';
import '../models/purchased_ticket.dart';
import 'ticket_eticket_screen.dart';
import 'info_screen.dart';
import '../models/event.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'intro_screen.dart';
import '../services/profile_prefs.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onSwitchTab});
  final void Function(int index)? onSwitchTab; // allow parent to switch bottom nav tab
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PurchasedTicket? _latestActive;
  bool _loading = true;
  User? _user; // firebase auth user
  String? _location;
  bool _editingName = false;
  final _nameCtrl = TextEditingController();
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await TicketStorage.instance.loadAll();
    final active = list.where((t) => !t.passed).toList()
      ..sort((a,b)=> b.purchasedAt.compareTo(a.purchasedAt));
    if (!mounted) return;
    final loc = await ProfilePrefs.instance.getLocation();
    setState(() {
      _latestActive = active.isNotEmpty ? active.first : null;
      _loading = false;
      _user = FirebaseAuth.instance.currentUser;
      _location = loc;
      _nameCtrl.text = _user?.displayName ?? '';
    });
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await UserProfileService.instance.updateDisplayName(name);
      // Refresh user instance
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      setState(() {
        _editingName = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: _load,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, padTop + 12, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 4),
                        const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                          onPressed: () {},
                        )
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Column(
                      children: [
                        _avatar(),
                        const SizedBox(height: 16),
                        _nameSection(),
                        const SizedBox(height: 6),
                        if ((_location ?? '').isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFFF4081)),
                              const SizedBox(width: 4),
                              Text(_location!, style: const TextStyle(color: Color(0xFFFF9AA2), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          )
                        else
                          const SizedBox(height: 0),
                        const SizedBox(height: 22),
                        _latestActive != null ? _followedEventCard(_latestActive!) : _emptyFollowed(),
                        const SizedBox(height: 22),
                        _menuCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameSection() {
    if (_editingName) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _nameCtrl,
              enabled: !_savingName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: const Color(0xFF2A1E3F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
            if (_savingName)
              const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
            else ...[
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFFFF4081)),
                onPressed: _saveName,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() { _editingName = false; _nameCtrl.text = _user?.displayName ?? ''; }),
              ),
            ]
        ],
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _editingName = true),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_user?.displayName ?? 'Guest User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Icon(Icons.edit, size: 16, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A1E3F),
            border: Border.all(color: const Color(0xFF503B6E), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.55), blurRadius: 22, offset: const Offset(0,10)),
              BoxShadow(color: const Color(0xFF673AB7).withOpacity(.25), blurRadius: 30, spreadRadius: 2),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF1C1C1E),
            backgroundImage: (_user?.photoURL != null && _user!.photoURL!.isNotEmpty)
                ? NetworkImage(_user!.photoURL!)
                : const AssetImage('assets/images/butter.jpg') as ImageProvider,
            child: (_user?.photoURL == null)
                ? const Icon(Icons.person, color: Colors.white54, size: 40)
                : null,
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (changed == true) {
                setState(() => _user = FirebaseAuth.instance.currentUser);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 10, offset: const Offset(0,4)),
                  BoxShadow(color: const Color(0xFFFF4081).withOpacity(.4), blurRadius: 18, spreadRadius: 1),
                ],
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  Widget _emptyFollowed() {
    if (_loading) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        decoration: _cardDecoration(),
        child: const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: _cardDecoration(),
      child: Row(
        children: const [
          Icon(Icons.event_available_outlined, color: Colors.white54),
          SizedBox(width: 14),
          Expanded(child: Text('No active ticket yet', style: TextStyle(color: Colors.white60, fontSize: 13))),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: const Color(0xFF1E1E22).withOpacity(.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      );

  Widget _followedEventCard(PurchasedTicket t) {
    final date = t.eventDate.toLocal();
    final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month-1];
    final dateStr = '${month} ${date.day.toString().padLeft(2,'0')} ${date.year}';
    return GestureDetector(
      onTap: () => _openTicket(t),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1E3F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x332A1E3F)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 26, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 70,
                height: 70,
                color: const Color(0xFF2A2A2E),
                child: Image.network(t.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(dateStr, style: const TextStyle(color: Color(0xFFFF9AA2), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4081), Color(0xFF673AB7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF4081).withOpacity(.35), blurRadius: 14, offset: const Offset(0,4)),
                      ],
                    ),
                    child: Text(t.zoneLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _openTicket(PurchasedTicket t) {
    final event = Event(
      id: t.eventId,
      title: t.title,
      imageUrl: t.imageUrl,
      location: t.location,
      date: t.eventDate,
      price: t.unitPrice,
      category: 'Event',
      description: '',
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketETicketScreen(
          event: event,
          zoneCode: t.zoneCode,
          zoneLabel: t.zoneLabel,
          unitPrice: t.unitPrice,
          quantity: t.quantity,
          purchasedTicket: t,
        ),
      ),
    );
  }

  Widget _menuCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _menuItem(Icons.edit_outlined, 'Edit Profile', () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (changed == true) {
              setState(() => _user = FirebaseAuth.instance.currentUser);
            }
          }),
          _divider(),
          _menuItem(Icons.confirmation_number_outlined, 'My Tickets', () {
            if (widget.onSwitchTab != null) {
              widget.onSwitchTab!(1); // index 1 for tickets
            } else {
              Navigator.of(context).maybePop();
            }
          }),
          _divider(),
          _menuItem(Icons.settings_outlined, 'Settings', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }),
          _divider(),
          _menuItem(Icons.info_outline, 'Information', () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InfoScreen()),
            );
          }),
          _divider(),
          _menuItem(Icons.logout, 'Log Out', () async {
            await FirebaseAuth.instance.signOut();
            TicketStorage.instance.resetMemory();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => OnBoardingPage()),
              (route) => false,
            );
          }, danger: true),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    const accent = Color(0xFFFF4081);
    const dangerColor = Color(0xFFE75480); // pinkish red for destructive
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFF3B3B3B), margin: const EdgeInsets.symmetric(horizontal: 18));
}
