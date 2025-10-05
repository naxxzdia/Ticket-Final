import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  Stream<List<OrderDoc>> _ordersStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
  .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => OrderDoc.fromMap(d.id, d.data())).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D031A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D031A),
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<OrderDoc>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return _error(snapshot.error.toString());
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return _empty();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemBuilder: (_, i) => _OrderTile(order: data[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: data.length,
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 64),
              SizedBox(height: 18),
              Text('No orders yet', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Buy a ticket and your orders will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, height: 1.3)),
            ],
          ),
        ),
      );

  Widget _error(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 54),
              const SizedBox(height: 16),
              Text('Error loading orders', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final OrderDoc order;

  String _formatDate(DateTime d) => "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')} ${d.year}";

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: () {
                final img = order.imageUrl; // now nullable
                if (img == null || img.isEmpty) {
                  return Container(width: 64, height: 64, color: Colors.white12, child: const Icon(Icons.image, color: Colors.white24, size: 28));
                }
                return Image.network(img, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.white12, child: const Icon(Icons.broken_image, color: Colors.white30, size: 26)));
              }(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.eventTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.event, color: Colors.white24, size: 14),
                    const SizedBox(width: 4),
                    Text(_formatDate(order.eventDate.toLocal()), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(width: 10),
                    Icon(Icons.confirmation_number_outlined, color: Colors.white24, size: 14),
                    const SizedBox(width: 4),
                    Text('${order.quantity} x ${order.zoneLabel}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusBadge(order.status),
                      const Spacer(),
                        Text('\$${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color bg; Color fg; String label;
    switch (s) {
      case 'paid':
        bg = const Color(0xFF274C2F); fg = const Color(0xFF6CFF92); label = 'PAID';
        break;
      case 'pending':
        bg = const Color(0xFF4D3C1F); fg = const Color(0xFFFFC861); label = 'PENDING';
        break;
      case 'cancelled':
        bg = const Color(0xFF4C1E1E); fg = const Color(0xFFFF6B6B); label = 'CANCELLED';
        break;
      default:
        bg = const Color(0xFF414141); fg = const Color(0xFFEEEEEE); label = s.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .7)),
    );
  }
}
