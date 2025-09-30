import 'package:flutter/material.dart';
import '../services/ticket_storage.dart';
import '../models/purchased_ticket.dart';
import '../models/event.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await TicketStorage.instance.loadAll();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  Future<void> _deleteOne(String id) async {
    await TicketStorage.instance.remove(id);
    await _load();
  }

  Future<void> _confirmClearAll() async {
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
    final shown = _segment == 0 ? active : passed;
    return Column(
      children: [
        _header(context),
        _segmented(),
        Expanded(
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.black,
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : shown.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 140),
                          Icon(_segment==0? Icons.confirmation_number_outlined: Icons.history, color: Colors.white24, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            _segment==0? 'No active tickets yet' : 'No past tickets',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text('Buy an event ticket and it will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, height: 1.3)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        itemBuilder: (_, i) => Dismissible(
                              key: ValueKey(shown[i].id),
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
                              onDismissed: (_) => _deleteOne(shown[i].id),
                              child: _TicketRow(ticket: shown[i]),
                            ),
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemCount: shown.length,
                      ),
          ),
        ),
      ],
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
              IconButton(
                tooltip: 'Clear All',
                onPressed: _all.isEmpty ? null : _confirmClearAll,
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
              ),
            ],
          ),
        ),
      );

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
            color: sel ? Colors.greenAccent.shade400 : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.black : Colors.white70,
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
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
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
                  Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('${_formatDate(dateLocal)} • ${_formatTime(dateLocal)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.greenAccent.shade400, borderRadius: BorderRadius.circular(8)),
                        child: Text(ticket.zoneLabel, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: passed ? Colors.white12 : Colors.greenAccent.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        passed ? 'Passed' : 'Active',
        style: TextStyle(
          color: passed ? Colors.white70 : Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: .5,
        ),
      ),
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
