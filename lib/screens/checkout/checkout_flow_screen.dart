import 'package:flutter/material.dart';
import '../../models/event.dart';
// (Removed duplicate imports)
import '../../services/ticket_storage.dart';
import '../../services/order_service.dart';
// import '../../util/id_utils.dart'; // removed (unused after Firestore integration)
import '../ticket_eticket_screen.dart';

class CheckoutFlowScreen extends StatefulWidget {
  const CheckoutFlowScreen({super.key, required this.event});
  final Event event;
  @override
  State<CheckoutFlowScreen> createState() => _CheckoutFlowScreenState();
}

class _CheckoutFlowScreenState extends State<CheckoutFlowScreen> {
  int _step = 0; // 0=checkout,1=payment,2=success
  int _quantity = 1;
  late List<_Zone> _zones;
  int _selectedZone = 0;
  String _paymentMethod = 'credit_card';
  bool _processing = false;

  double get _unitPrice => _zones[_selectedZone].price;
  double get _total => _unitPrice * _quantity;

  @override
  void initState() {
    super.initState();
    _zones = _deriveZones(widget.event);
  }

  List<_Zone> _deriveZones(Event e) {
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
        _Zone('VVIP','VVIP', vvip),
        _Zone('VIP','VIP', vip),
        _Zone('REG','Regular', reg),
      ];
    }
    final base = e.price <= 0 ? 100.0 : e.price.toDouble();
    return [
      _Zone('VVIP','VVIP', base * 1.5),
      _Zone('VIP','VIP', base),
      _Zone('REG','Regular', base * 0.6),
    ];
  }

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  Future<void> _payNow() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _step = 2;
    });
  }

  Future<void> _viewTicket() async {
    final zone = _zones[_selectedZone];
    String? orderId;
    try {
      orderId = await OrderService.instance.createOrder(
        event: widget.event,
        zoneCode: zone.code,
        zoneLabel: zone.label,
        unitPrice: zone.price,
        quantity: _quantity,
        paymentMethod: _paymentMethod,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e')),
        );
      }
      return;
    }
    // Local persistence kept (optional) - could remove if fully cloud driven
    try {
      await TicketStorage.instance.add(
        eventId: widget.event.id,
        title: widget.event.title,
        imageUrl: widget.event.imageUrl,
        location: widget.event.location,
        eventDate: widget.event.date,
        zoneCode: zone.code,
        zoneLabel: zone.label,
        unitPrice: zone.price,
        quantity: _quantity,
        orderId: orderId,
      );
    } catch (_) {
      // Ignore local persistence failure
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TicketETicketScreen(
          event: widget.event,
          zoneCode: zone.code,
          zoneLabel: zone.label,
          unitPrice: zone.price,
          quantity: _quantity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D031A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D031A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back, color: const Color(0xFFFF4081)),
          onPressed: _step == 0 ? () => Navigator.of(context).maybePop() : _back,
          splashRadius: 24,
          tooltip: 'Back',
        ),
        title: Text(_titleForStep(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          const SizedBox(height: 8),
            Expanded(child: _buildStep()),
          _bottomBar(),
        ],
      ),
    );
  }

  String _titleForStep() {
    switch (_step) {
      case 0: return 'Checkout';
      case 1: return 'Payment';
      case 2: return 'Success';
    }
    return '';
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _checkoutStep();
      case 1: return _paymentStep();
      case 2: return _successStep();
    }
    return const SizedBox();
  }

  Widget _checkoutStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _EventSummaryCard(event: widget.event),
        const SizedBox(height: 18),
        _zoneSelector(),
        const SizedBox(height: 24),
        _quantitySelector(),
        const SizedBox(height: 28),
        _orderSummary(showPaymentRow: false),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _paymentStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _orderSummary(showPaymentRow: true),
        const SizedBox(height: 26),
        const Text('Payment Method', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        for (final m in _paymentMethods()) ...[
          _paymentTile(m),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 130),
      ],
    );
  }

  Widget _successStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFF673AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 28, offset: const Offset(0, 6)),
                BoxShadow(color: const Color(0xFFFF4081).withOpacity(.35), blurRadius: 38, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
          ),
          const SizedBox(height: 26),
          const Text('Payment Successful', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Your ticket has been generated and is ready to view.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.35)),
          ),
        ],
      ),
    );
  }

  bool _primaryActionEnabled() => !_processing;

  void _onPrimaryAction() {
    if (_step == 0) {
      _next();
    } else if (_step == 1) {
      _payNow();
    } else if (_step == 2) {
      _viewTicket();
    }
  }

  String _primaryLabel() {
    switch (_step) {
      case 0: return 'Continue to Payment';
      case 1: return _processing ? 'Processing...' : 'Pay \$${_total.toStringAsFixed(0)}';
      case 2: return 'View Ticket';
    }
    return '';
  }

  Widget _zoneSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zone', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (int i = 0; i < _zones.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedZone = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _SelectDot(selected: _selectedZone == i),
                    const SizedBox(width: 14),
                    _ZoneIcon(color: _zoneColor(i)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _zones[i].label,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '\$${_zones[i].price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.w700),
                    )
                  ],
                ),
              ),
            ),
            if (i < _zones.length - 1) const Divider(color: Colors.white12, height: 1),
          ]
        ],
      ),
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
          _RoundIconButton(
            icon: Icons.remove,
            onTap: () => setState(() => _quantity = (_quantity - 1).clamp(1, 10)),
            enabled: _quantity > 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
            _RoundIconButton(
            icon: Icons.add,
            onTap: () => setState(() => _quantity = (_quantity + 1).clamp(1, 10)),
            enabled: _quantity < 10,
          ),
        ],
      ),
    );
  }

  Widget _orderSummary({required bool showPaymentRow}) {
    final zone = _zones[_selectedZone];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332A1E3F)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _summaryRow('Tickets', '${_quantity} x ${zone.label}'),
          _summaryRow('Sub Total', '\$${_total.toStringAsFixed(0)}'),
          _summaryRow('Wallet Balance', '-\$0'),
          _summaryRow('Discount', '-\$0'),
          const Divider(color: Colors.white12, height: 26),
          _summaryRow('Total Amount', '\$${_total.toStringAsFixed(0)}', bold: true),
          if (showPaymentRow) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Text(_paymentLabel(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Edit', style: TextStyle(color: Colors.white70)),
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  String _paymentLabel() {
    switch (_paymentMethod) {
      case 'credit_card': return 'Credit Card';
      case 'paypal': return 'Paypal';
      case 'apple_pay': return 'Apple Pay';
      case 'google_pay': return 'Google Pay';
    }
    return 'Payment';
  }

  List<_PaymentMethod> _paymentMethods() => const [
        _PaymentMethod(id: 'credit_card', label: 'Credit Card', logos: ['MC', 'AMEX', 'VISA']),
        _PaymentMethod(id: 'paypal', label: 'Paypal', logos: ['PP']),
        _PaymentMethod(id: 'apple_pay', label: 'Apple Pay', logos: ['Pay']),
        _PaymentMethod(id: 'google_pay', label: 'Google Pay', logos: ['GPay']),
      ];

  Widget _paymentTile(_PaymentMethod method) {
    final selected = _paymentMethod == method.id;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _paymentMethod = method.id),
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
            _SelectDot(selected: selected),
            const SizedBox(width: 14),
            Expanded(child: Text(method.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
            Row(children: [for (final l in method.logos) ...[_logoBadge(l), const SizedBox(width: 6)]])
          ],
        ),
      ),
    );
  }

  Widget _logoBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Color _zoneColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF6F3CFF);
      case 1:
        return const Color(0xFF3C88FF);
      default:
        return const Color(0xFF9AA4B1);
    }
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, -6))],
        ),
        child: Row(
          children: [
            if (_step < 2)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: .3)),
                  const SizedBox(height: 2),
                  Text(
                    '\$${_total.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFFFF4081), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: .2),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 54,
                child: _GradientActionButton(
                  enabled: _primaryActionEnabled(),
                  loading: _processing,
                  label: _primaryLabel(),
                  onTap: _primaryActionEnabled() ? _onPrimaryAction : null,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    final items = const ['Checkout', 'Payment', 'Success'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _StepPill(label: (i + 1).toString(), active: step == i, done: step > i),
            if (i < items.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: step > i
                          ? const [Color(0xFFFF4081), Color(0xFF673AB7)]
                          : const [Color(0xFF4A3B6B), Color(0xFF4A3B6B)],
                    ),
                  ),
                ),
              ),
          ]
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.active, required this.done});
  final String label;
  final bool active;
  final bool done;
  @override
  Widget build(BuildContext context) {
  final LinearGradient? bg = active
    ? const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFF673AB7)])
    : (done
      ? const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFF673AB7)])
      : null);
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: !active && !done ? Border.all(color: const Color(0xFF4A3B6B), width: 1.2) : null,
  gradient: done && !active ? const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFF673AB7)]) : null,
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: bg),
          alignment: Alignment.center,
          child: Text(done ? '✓' : label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
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
  const _Zone(this.code, this.label, this.price);
}

class _EventSummaryCard extends StatelessWidget {
  const _EventSummaryCard({required this.event});
  final Event event;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 86,
              height: 66,
              color: const Color(0xFF2A1C42),
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(event.location.split(',').first,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_dateLine(event.date),
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _dateLine(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} | ${d.year}';
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    const inactiveBorder = Color(0xFF8881A9);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected ? null : Border.all(color: inactiveBorder, width: 2),
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFF673AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4081).withOpacity(.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: selected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
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
      opacity: enabled ? 1 : .35,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 24,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF3B2A54),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF503B6E), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFFFF4081), size: 18),
        ),
      ),
    );
  }
}

Widget _summaryRow(String label, String value, {bool bold = false}) {
  final isMoney = value.contains('\$');
  final valueColor = isMoney ? const Color(0xFFFF4081) : Colors.white;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFFBDBDBD),
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onTap,
  });
  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFFD1DC), Color(0xFFFF4081), Color(0xFF673AB7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4081).withOpacity(.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: enabled && !loading ? onTap : null,
            borderRadius: BorderRadius.circular(40),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// End of file
