import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/purchased_ticket.dart';
import '../services/ticket_storage.dart';
import 'ticket_eticket_screen.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});
  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> with AutomaticKeepAliveClientMixin {
  int _segment = 0; // 0 active, 1 passed
  List<PurchasedTicket> _all = [];
  bool _loading = true;
  final _activeScroll = ScrollController();
  final _passedScroll = ScrollController();
  bool _useCloud = false; // toggle between local storage and Firestore

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_useCloud) {
      await _loadFromFirestore();
      return;
    }
    final data = await TicketStorage.instance.loadAll();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  Future<void> _loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() { _all = []; _loading = false; });
      }
      return;
    }
    try {
    final query = await FirebaseFirestore.instance
      .collection('tickets')
      .where('userId', isEqualTo: uid)
      .orderBy('eventDate')
      .get();
      final now = DateTime.now();
      final items = query.docs.map((doc) {
        final m = doc.data();
        DateTime parseDate(dynamic v) {
          if (v == null) return now;
            if (v is Timestamp) return v.toDate();
          return DateTime.tryParse(v.toString()) ?? now;
        }
        final date = parseDate(m['eventDate']);
        DateTime parsePurchased(dynamic v) {
          if (v == null) return date; // fallback
          if (v is Timestamp) return v.toDate();
          return DateTime.tryParse(v.toString()) ?? date;
        }
        final purchasedAt = parsePurchased(m['purchasedAt']);
        final unitPrice = (m['unitPrice'] is num) ? (m['unitPrice'] as num).toDouble() : 0.0;
        return PurchasedTicket(
          id: doc.id,
          eventId: m['eventId'] ?? '',
          title: m['eventTitle'] ?? 'Event',
          imageUrl: m['imageUrl'] ?? '',
          location: m['eventLocation'] ?? '',
          eventDate: date,
          zoneCode: m['zoneCode'] ?? '',
          zoneLabel: m['zoneLabel'] ?? '',
          unitPrice: unitPrice,
          quantity: 1, // each ticket doc is a single seat record
          total: unitPrice,
          orderId: m['orderId'] ?? '',
          purchasedAt: purchasedAt,
          passed: date.isBefore(now),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _all = []; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cloud tickets: $e')),
      );
    }
  }

  Future<void> _deleteOne(String id) async {
    if (_useCloud) return; // deletion of cloud tickets not implemented yet
    await TicketStorage.instance.remove(id);
    await _load();
  }

  Future<void> _deleteCloudTicket(String id) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final ref = FirebaseFirestore.instance.collection('tickets').doc(id);
      final snap = await ref.get();
      if (snap.exists) {
        final data = snap.data();
        if (data != null && data['userId'] == uid) {
          await ref.delete();
        }
      }
      // Optimistic UI: remove locally
      if (mounted) {
        setState(() { _all.removeWhere((t) => t.id == id); });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    if (_useCloud) return; // do nothing for cloud mode
    if (_all.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Clear all tickets?', style: TextStyle(color: Colors.white,fontSize:16,fontWeight: FontWeight.w600)),
        content: const Text('This will remove every stored ticket from this device.', style: TextStyle(color: Colors.white70,fontSize:14,height:1.3)),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Cancel')),
          TextButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('Clear All', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      await TicketStorage.instance.clearAll();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final active = _all.where((t) => !t.passed).toList();
    final passed = _all.where((t) => t.passed).toList();
    return Column(
      children: [
        _header(context),
        _segmented(),
        Expanded(
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1A1A1A), // Updated background color
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : IndexedStack(
                    index: _segment,
                    children: [
                      _buildList(active, false, _activeScroll),
                      _buildList(passed, true, _passedScroll),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<PurchasedTicket> data, bool isPassed, ScrollController controller) {
    if (data.isEmpty) {
      return ListView(
        controller: controller,
        children: [
          const SizedBox(height: 140),
          Icon(isPassed ? Icons.history : Icons.confirmation_number_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'No past tickets' : 'No active tickets yet',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text('Buy an event ticket and it will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, height: 1.3)),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      itemBuilder: (_, i) {
        final row = _TicketRow(ticket: data[i]);
        if (_useCloud) {
          return Dismissible(
            key: ValueKey(data[i].id),
            background: _swipeBg(Colors.redAccent, Icons.delete_outline, 'Delete'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E22),
                      title: const Text('Delete cloud ticket?', style: TextStyle(color: Colors.white,fontSize:16,fontWeight: FontWeight.w600)),
                      content: const Text('This will remove this ticket from your account.', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Cancel')),
                        TextButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  ) ?? false;
            },
            onDismissed: (_) => _deleteCloudTicket(data[i].id),
            child: row,
          );
        }
        return Dismissible(
          key: ValueKey(data[i].id),
          background: _swipeBg(Colors.redAccent, Icons.delete_outline, 'Delete'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E22),
                    title: const Text('Delete ticket?', style: TextStyle(color: Colors.white,fontSize:16,fontWeight: FontWeight.w600)),
                    content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Cancel')),
                      TextButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ) ?? false;
          },
          onDismissed: (_) => _deleteOne(data[i].id),
          child: row,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: data.length,
    );
  }

  Widget _swipeBg(Color color, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.85),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Row(
            children: [
              const Text('Tickets', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() { _useCloud = !_useCloud; });
                  _load();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                    gradient: _useCloud ? const LinearGradient(colors:[Color(0xFFFF4081), Color(0xFF673AB7)]) : null,
                    color: _useCloud ? null : const Color(0xFF2F2F2F),
                  ),
                  child: Row(
                    children: [
                      Icon(_useCloud ? Icons.cloud_done : Icons.storage, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(_useCloud ? 'Cloud' : 'Local', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildTrashButton(),
            ],
          ),
        ),
      );

  Widget _buildTrashButton() {
    final disabled = _useCloud || _all.isEmpty;
    final baseIcon = Icon(Icons.delete_sweep_outlined, size: 24, color: disabled ? Colors.white24 : Colors.white);
    if (disabled) return IconButton(tooltip: _useCloud ? 'Disabled in cloud mode' : 'Clear All', onPressed: null, icon: baseIcon);
    return InkResponse(
      onTap: _confirmClearAll,
      radius: 24,
      splashColor: const Color(0xFFE75480).withOpacity(.25),
      highlightColor: Colors.transparent,
      child: ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFFFF4081), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(r),
        child: baseIcon,
      ),
    );
  }

  Widget _segmented() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1D),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _segBtn(0, 'Active'),
                _segBtn(1, 'Passed'),
              ],
            ),
      ),
    );
  }

  Widget _segBtn(int index, String label) {
    final sel = _segment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: sel ? null : const Color(0xFF2F2F2F),
            gradient: sel
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFFD1DC), Color(0xFFFF4081), Color(0xFF673AB7)],
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : const Color(0xFFBDBDBD),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});
  final PurchasedTicket ticket;

  String _formatDate(DateTime d) => "${d.day.toString().padLeft(2,'0')} ${_month(d.month)}";
  String _formatTime(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2,'0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $suffix';
  }
  String _month(int m) => const ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m-1];

  @override
  Widget build(BuildContext context) {
    final passed = ticket.passed || ticket.eventDate.isBefore(DateTime.now());
    final dateLocal = ticket.eventDate.toLocal();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TicketETicketScreen(
              event: _stubEventFromTicket(), // minimal event for palette + fallback
              zoneCode: ticket.zoneCode,
              zoneLabel: ticket.zoneLabel,
              unitPrice: ticket.unitPrice,
              quantity: ticket.quantity,
              purchasedTicket: ticket,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242129), // New ticket card color per spec
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3A3055).withOpacity(0.30), width: 1), // Optional subtle border
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.40), blurRadius: 8, offset: const Offset(0,4)), // Soft shadow
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            _thumb(ticket.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('${_formatDate(dateLocal)} • ${_formatTime(dateLocal)}', style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _zoneBadge(ticket.zoneLabel),
                      const SizedBox(width: 8),
                      Text('x${ticket.quantity}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _statusBadge(passed),
          ],
        ),
      ),
    );
  }
  Widget _thumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 70,
        height: 70,
        color: const Color(0xFF2A2A2E),
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white24)),
      ),
    );
  }

  Widget _statusBadge(bool passed) {
    if (!passed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4081), Color(0xFF673AB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(.20),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Active',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: .5,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6D6A75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Passed',
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: .5,
        ),
      ),
    );
  }

  Widget _zoneBadge(String zone) {
    final upper = zone.toUpperCase();
    if (upper == 'VVIP') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4081), Color(0xFF673AB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text('VVIP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5)),
      );
    }
    if (upper == 'VIP') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9AA2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('VIP', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6D6A75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(upper, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5)),
    );
  }

  Event _stubEventFromTicket() => Event(
        id: ticket.eventId,
        title: ticket.title,
        imageUrl: ticket.imageUrl,
        location: ticket.location,
        date: ticket.eventDate,
        price: ticket.unitPrice,
        category: 'Event',
        description: '',
      );
}
