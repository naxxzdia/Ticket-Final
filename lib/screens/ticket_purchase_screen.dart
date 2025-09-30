// DEPRECATED: replaced by 3-step checkout flow in checkout/checkout_flow_screen.dart
// Keeping temporarily in case of rollback; can be deleted later.
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/ticket_storage.dart';
import '../util/id_utils.dart';
import 'ticket_eticket_screen.dart';

class TicketPurchaseScreen extends StatefulWidget {
  const TicketPurchaseScreen({super.key, required this.event});
  final Event event;

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  late final List<_Zone> zones;

  int _selectedIndex = 0;
  int _quantity = 1;
  String _payment = 'credit_card';

  double get _unitPrice => zones[_selectedIndex].price;
  double get _total => _unitPrice * _quantity;

  void _changeZone(int i) => setState(() => _selectedIndex = i);
  void _incQty() => setState(() => _quantity = (_quantity + 1).clamp(1, 10));
  void _decQty() => setState(() => _quantity = (_quantity - 1).clamp(1, 10));

  @override
  void initState() {
    super.initState();
    zones = _deriveZones(widget.event);
  }

  List<_Zone> _deriveZones(Event e) {
    // If backend provides explicit zonePrices use them, else derive from base price.
    final zp = e.zonePrices;
    if (zp != null && zp.isNotEmpty) {
      double? vvip = (zp['VVIP'] is num) ? (zp['VVIP'] as num).toDouble() : null;
      double? vip = (zp['VIP'] is num) ? (zp['VIP'] as num).toDouble() : null;
      double? reg = (zp['REG'] is num) ? (zp['REG'] as num).toDouble() : null;
      final base = e.price <= 0 ? 100.0 : e.price.toDouble();
      vip ??= vvip != null ? (vvip * 0.72) : base;
      reg ??= (vip * 0.6);
      vvip ??= (vip * 1.4);
      return [
        _Zone(code: 'VVIP', label: 'VVIP', price: vvip),
        _Zone(code: 'VIP', label: 'VIP', price: vip),
        _Zone(code: 'REG', label: 'Regular', price: reg),
      ];
    }
    final base = e.price <= 0 ? 100.0 : e.price.toDouble();
    return [
      _Zone(code: 'VVIP', label: 'VVIP', price: base * 1.5),
      _Zone(code: 'VIP', label: 'VIP', price: base),
      _Zone(code: 'REG', label: 'Regular', price: (base * 0.6)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D031A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D031A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Select Tickets', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _StageMap(
                  zones: zones,
                  selected: _selectedIndex,
                  onTapZone: _changeZone,
                ),
                const SizedBox(height: 28),
                _buildZoneRadioList(),
                const SizedBox(height: 24),
                _quantitySelector(),
                const SizedBox(height: 28),
                _paymentSelector(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _bottomBar(context),
        ],
      ),
    );
  }

  Widget _buildZoneRadioList() {
    return Column(
      children: [
        for (int i = 0; i < zones.length; i++) ...[
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _changeZone(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _SelectDot(selected: _selectedIndex == i, color: _zoneColor(i)),
                  const SizedBox(width: 14),
                  _ZoneIcon(color: _zoneColor(i)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      zones[i].label,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '\$${zones[i].price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ),
          ),
          if (i < zones.length - 1) const Divider(color: Colors.white12, height: 1),
        ]
      ],
    );
  }

  Widget _quantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Text('Quantity', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const Spacer(),
          _RoundIconButton(icon: Icons.remove, onTap: _decQty, enabled: _quantity > 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
            _RoundIconButton(icon: Icons.add, onTap: _incQty, enabled: _quantity < 10),
        ],
      ),
    );
  }

  Widget _paymentSelector() {
    final methods = <_PaymentMethod>[
      _PaymentMethod(id: 'credit_card', label: 'Credit Card', logos: const ['MC','AMEX','VISA']),
      _PaymentMethod(id: 'paypal', label: 'Paypal', logos: const ['PP']),
      _PaymentMethod(id: 'apple_pay', label: 'Apple Pay', logos: const ['Pay']),
      _PaymentMethod(id: 'google_pay', label: 'Google Pay', logos: const ['GPay']),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final m in methods) ...[
          _paymentTile(m, isLast: m == methods.last),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _paymentTile(_PaymentMethod method, {bool isLast = false}) {
    final selected = _payment == method.id;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _payment = method.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1230),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? const Color(0xFF6F3CFF) : Colors.white12, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            _SelectDot(selected: selected, color: const Color(0xFF6F3CFF)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(method.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Row(
              children: [
                for (final l in method.logos) ...[
                  _logoBadge(l),
                  const SizedBox(width: 6),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _logoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF140A26),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -8))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                Text('\$${_total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E19FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  onPressed: () async {
                    final selected = zones[_selectedIndex];
                    // Generate a lightweight pseudo order id similar to e-ticket screen logic
                    final orderId = generateOrderId(widget.event.id);
                    // Persist ticket
                    await TicketStorage.instance.add(
                      eventId: widget.event.id,
                      title: widget.event.title,
                      imageUrl: widget.event.imageUrl,
                      location: widget.event.location,
                      eventDate: widget.event.date,
                      zoneCode: selected.code,
                      zoneLabel: selected.label,
                      unitPrice: selected.price,
                      quantity: _quantity,
                      orderId: orderId,
                    );
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TicketETicketScreen(
                          event: widget.event,
                          zoneCode: selected.code,
                          zoneLabel: selected.label,
                          unitPrice: selected.price,
                          quantity: _quantity,
                        ),
                      ),
                    );
                  },
                  child: const Text('Buy Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _zoneColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF6F3CFF); // VVIP purple
      case 1:
        return const Color(0xFF3C88FF); // VIP blue
      default:
        return const Color(0xFF9AA4B1); // Regular gray
    }
  }
}

class _PaymentMethod {
  final String id;
  final String label;
  final List<String> logos;
  const _PaymentMethod({required this.id, required this.label, this.logos = const []});
}

class _Zone {
  final String code;
  final String label;
  final double price;
  const _Zone({required this.code, required this.label, required this.price});
}

class _StageMap extends StatelessWidget {
  const _StageMap({required this.zones, required this.selected, required this.onTapZone});
  final List<_Zone> zones;
  final int selected;
  final ValueChanged<int> onTapZone;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3/4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B0F33), Color(0xFF120825)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text('STAGE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
            const Spacer(),
            _zoneBlock(0, flex: 5),
            const SizedBox(height: 10),
            _zoneBlock(1, flex: 4),
            const SizedBox(height: 10),
            _zoneBlock(2, flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _zoneBlock(int index, {required int flex}) {
    final zone = zones[index];
    final bool isSel = index == selected;
    final baseColor = _zoneColor(index);
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onTapZone(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSel ? baseColor : baseColor.withOpacity(.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSel ? Colors.white : Colors.white24,
              width: isSel ? 2 : 1,
            ),
            boxShadow: isSel
                ? [
                    BoxShadow(color: baseColor.withOpacity(.6), blurRadius: 22, spreadRadius: 1),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            zone.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSel ? 16 : 14,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
        ),
      ),
    );
  }

  Color _zoneColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF6F3CFF); // VVIP
      case 1:
        return const Color(0xFF3C88FF); // VIP
      default:
        return const Color(0xFF9AA4B1); // Regular
    }
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected, required this.color});
  final bool selected;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? color : Colors.white54, width: 2),
        color: selected ? color : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

class _ZoneIcon extends StatelessWidget {
  const _ZoneIcon({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(.55)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.event_seat, size: 16, color: Colors.white),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.enabled = true});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .4,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 22,
        child: Container(
          width: 34,
            height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2A1C42),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
