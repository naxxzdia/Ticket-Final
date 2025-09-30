import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ticket_storage.dart';
import '../models/purchased_ticket.dart';
import 'ticket_eticket_screen.dart';
import '../models/event.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'intro_screen.dart';
import '../services/profile_prefs.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // gradient backdrop
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF12081F), Color(0xFF06060A)],
                ),
              ),
            ),
          ),
          // noise / subtle overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(.02), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.black,
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
                        Text(_user?.displayName ?? 'Guest User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        if ((_location ?? '').isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(_location!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

  Widget _avatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF6F3CFF), Color(0xFF4E19FF)]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 18, offset: const Offset(0,8))],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF1C1C1E),
            backgroundImage: (_user?.photoURL != null && _user!.photoURL!.isNotEmpty)
                ? NetworkImage(_user!.photoURL!)
                : const AssetImage('assets/images/taro1.1.jpg') as ImageProvider,
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
                color: const Color(0xFFFF5DA2),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 10)],
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
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
        decoration: _cardDecoration(),
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
                  Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t.zoneLabel, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
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
          _menuItem(Icons.info_outline, 'Information', () {}),
          _divider(),
          _menuItem(Icons.logout, 'Log Out', () async {
            await FirebaseAuth.instance.signOut();
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: danger ? const Color(0xFFFF5DA2) : Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: danger ? const Color(0xFFFF5DA2) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 18));
}
