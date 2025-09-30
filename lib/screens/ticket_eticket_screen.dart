import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event.dart';
import '../models/purchased_ticket.dart';
import '../util/id_utils.dart';

class TicketETicketScreen extends StatefulWidget {
  const TicketETicketScreen({
    super.key,
    required this.event,
    required this.zoneCode,
    required this.zoneLabel,
    required this.unitPrice,
    required this.quantity,
    this.purchasedTicket,
  });
  final Event event; // still passed for palette image & fallback
  final String zoneCode;
  final String zoneLabel;
  final double unitPrice;
  final int quantity;
  final PurchasedTicket? purchasedTicket; // when coming from stored list

  @override
  State<TicketETicketScreen> createState() => _TicketETicketScreenState();
}

class _TicketETicketScreenState extends State<TicketETicketScreen> {
  PaletteGenerator? _palette;
  Color? _dominant;
  Color? _vibrant;
  bool _showQr = false;
  bool _capturing = false;
  final GlobalKey _captureKey = GlobalKey();

  String _formatDate(DateTime d) => "${d.day.toString().padLeft(2,'0')} ${_month(d.month)} ${d.year}";
  String _formatTime(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2,'0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $suffix';
  }
  String _month(int m) => const ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m-1];

  String _orderId() {
    if (widget.purchasedTicket != null) return widget.purchasedTicket!.orderId;
    return generateOrderId(widget.event.id);
  }

  String _barcodePayload() {
    final base = _orderId();
    final qty = widget.purchasedTicket?.quantity ?? widget.quantity;
    final zone = widget.purchasedTicket?.zoneCode ?? widget.zoneCode;
    return base + zone + qty.toString().padLeft(2,'0');
  }

  String _seatLabel() {
    final qty = widget.purchasedTicket?.quantity ?? widget.quantity;
    final start = (widget.event.id.hashCode % 60) + 10; // 10..69
    final end = start + qty - 1;
    return qty == 1 ? start.toString() : '$start-$end';
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }
  
  Future<void> _extractPalette() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.event.imageUrl),
        size: const Size(300, 180),
        maximumColorCount: 16,
      );
      if (!mounted) return;
      setState(() {
        _palette = palette;
        _dominant = palette.dominantColor?.color;
        _vibrant = palette.vibrantColor?.color ?? palette.lightVibrantColor?.color ?? palette.darkVibrantColor?.color;
      });
    } catch (_) {
      // ignore palette errors silently
    }
  }

  Future<void> _captureAndShare() async {
    setState(() => _capturing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
  final uiImage = await boundary.toImage(pixelRatio: 2.5);
  final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final file = XFile.fromData(bytes, name: 'ticket.png', mimeType: 'image/png');
      await Share.shareXFiles([file], text: '${widget.event.title} – Ticket');
    } catch (e) {
      if (mounted) _showSnack(context, 'Share failed');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _extractPalette();
  }

  @override
  Widget build(BuildContext context) {
  final dateLocal = (widget.purchasedTicket?.eventDate ?? widget.event.date).toLocal();
  final qty = widget.purchasedTicket?.quantity ?? widget.quantity;
  final unit = widget.purchasedTicket?.unitPrice ?? widget.unitPrice;
  final zoneLabel = widget.purchasedTicket?.zoneLabel ?? widget.zoneLabel;
  final zoneCode = widget.purchasedTicket?.zoneCode ?? widget.zoneCode;
        final startColor = ((_palette?.dominantColor?.color) ?? _dominant ?? const Color(0xFF141417)).withOpacity(.95);
    final accent = _vibrant ?? _dominant ?? const Color(0xFF5A5A5F);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                  // base gradient; dynamic overlay below
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF060608), Color(0xFF060608)],
                  )
              ),
            ),
          ),
          // dynamic tinted radial glow using extracted color
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.85),
                    radius: 1.2,
                    colors: [startColor.withOpacity(.55), Colors.transparent],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Text('Ticket Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    key: _captureKey,
                    child: Column(
                      children: [
                        _Poster(imageUrl: widget.purchasedTicket?.imageUrl ?? widget.event.imageUrl),
                        const SizedBox(height: 18),
                        _DarkTicketCard(
                          accent: accent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.purchasedTicket?.title ?? widget.event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 16),
                              _infoTwoCol('Date', _formatDate(dateLocal), 'Time', _formatTime(dateLocal)),
                              const SizedBox(height: 12),
                              _infoTwoCol('Place', (widget.purchasedTicket?.location ?? widget.event.location).split(',').first, 'Seat', _seatLabel()),
                              const SizedBox(height: 12),
                              _infoTwoCol('Check In', zoneLabel, 'Order ID', _orderId()),
                              const SizedBox(height: 12),
                              _infoTwoCol('Tickets', qty.toString(), 'Unit Price', '\$${unit.toStringAsFixed(0)}'),
                              const SizedBox(height: 12),
                              _infoTwoCol('Total', '\$${(unit * qty).toStringAsFixed(0)}', 'Code', zoneCode),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_showQr ? 'QR Code' : 'Barcode', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                                    onPressed: () => setState(() => _showQr = !_showQr),
                                    icon: Icon(_showQr ? Icons.barcode_reader : Icons.qr_code_2, size: 18),
                                    label: Text(_showQr ? 'Show Barcode' : 'Show QR'),
                                  ),
                                ],
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: _showQr
                                    ? Container(
                                        key: const ValueKey('qr'),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C1C1E),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: QrImageView(
                                          data: _barcodePayload(),
                                          size: 150,
                                          backgroundColor: Colors.white,
                                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                                        ),
                                      )
                                    : _BarcodeStub(code: _barcodePayload(), dark: true),
                              ),
                              const SizedBox(height: 8),
                              // spacer below the ticket content before scroll bottom
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActions(
              onShare: _capturing ? null : () => _captureAndShare(),
              onQrToggle: () => setState(() => _showQr = !_showQr),
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTwoCol(String l1, String v1, String l2, String v2) {
    const labelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: .2, color: Colors.white70);
    const valueStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l1, style: labelStyle),
              const SizedBox(height: 4),
              Text(v1, style: valueStyle),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l2, style: labelStyle),
              const SizedBox(height: 4),
              Text(v2, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
// Replaced old card + bottom panel with new components below

  class _Poster extends StatelessWidget {
    const _Poster({required this.imageUrl});
    final String imageUrl;
    @override
    Widget build(BuildContext context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 12/9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF222226),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 42),
                  ),
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF222226),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(.05), Colors.black.withOpacity(.55)],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  class _DarkTicketCard extends StatelessWidget {
    const _DarkTicketCard({required this.child, required this.accent});
    final Widget child;
    final Color accent;
    @override
    Widget build(BuildContext context) {
      return ClipPath(
        clipper: _TicketClipper(),
        child: Stack(
          children: [
            // glass blur layer
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF222226).withOpacity(.55),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withOpacity(.18), const Color(0xFF1D1D21).withOpacity(.75)],
                ),
                border: Border.all(color: accent.withOpacity(.45), width: 1),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(.35), blurRadius: 28, spreadRadius: 1, offset: const Offset(0, 10)),
                  BoxShadow(color: Colors.black.withOpacity(.65), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 22)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: child,
            ),
          ],
        ),
      );
    }
  }

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 18.0;
    final path = Path();
    // Outer rect
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)));
    // Notches (use difference when drawing with clipPath)
    // We'll carve two circles out; to mimic physical ticket.
    final notch1 = Path()..addOval(Rect.fromCircle(center: Offset(0, size.height * .45), radius: radius));
    final notch2 = Path()..addOval(Rect.fromCircle(center: Offset(size.width, size.height * .45), radius: radius));
    return Path.combine(PathOperation.difference, path, Path.combine(PathOperation.union, notch1, notch2));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BarcodeStub extends StatelessWidget {
  const _BarcodeStub({required this.code, this.dark = false});
  final String code;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    // Simple mock barcode using random vertical bars.
    final bars = List.generate(code.length * 3, (i) => (i % 4 == 0));
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border.all(color: dark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < bars.length; i++) ...[
            Container(
              width: bars[i] ? 3 : 1.4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: 60 + (bars[i] ? 20 : 0),
              color: dark ? Colors.white : Colors.black,
            ),
          ],
        ],
      ),
    );
  }
}


class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onShare, required this.onQrToggle, required this.accent});
  final VoidCallback? onShare;
  final VoidCallback onQrToggle;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + pad.bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xAA000000)],
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _ActionBtn(label: 'Share', icon: Icons.ios_share_rounded, onTap: onShare, accent: accent)),
          const SizedBox(width: 14),
          Expanded(child: _ActionBtn(label: 'QR / Barcode', icon: Icons.qr_code_rounded, onTap: onQrToggle, accent: accent)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.icon, required this.onTap, required this.accent});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.withOpacity(.35),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: accent.withOpacity(.65), width: 1)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// _MockQr removed – replaced by real QR widget via qr_flutter
