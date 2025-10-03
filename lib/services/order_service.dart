import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

/// Service responsible for writing orders & generating tickets in Firestore.
/// Minimal v1 (single event per order, general admission / zone-based).
class OrderService {
  OrderService._();
  static final instance = OrderService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Create an order in `orders` collection and generate ticket docs.
  /// Returns created orderId.
  Future<String> createOrder({
    required Event event,
    required String zoneCode,
    required String zoneLabel,
    required double unitPrice,
    required int quantity,
    required String paymentMethod,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');

    final orderRef = _db.collection('orders').doc();
    final ticketsColl = _db.collection('tickets');

    final total = unitPrice * quantity;

    await _db.runTransaction((txn) async {
      // Basic order doc
      txn.set(orderRef, {
        'userId': user.uid,
        'eventId': event.id,
        'eventTitle': event.title,
        'eventDate': event.date.toUtc(),
        'eventLocation': event.location,
        'imageUrl': event.imageUrl,
        'zoneCode': zoneCode,
        'zoneLabel': zoneLabel,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalAmount': total,
        'paymentMethod': paymentMethod,
        'status': 'paid', // since current flow simulates instant success
        'paidAt': FieldValue.serverTimestamp(),
        'currency': 'USD',
        'ticketsBatchDone': true,
      });

      for (int i = 0; i < quantity; i++) {
        final ticketRef = ticketsColl.doc();
        txn.set(ticketRef, {
          'orderId': orderRef.id,
          'eventId': event.id,
          'userId': user.uid,
          'sequence': i + 1,
          'status': 'valid',
          'issuedAt': FieldValue.serverTimestamp(),
          'purchasedAt': FieldValue.serverTimestamp(),
          'qrData': '${orderRef.id}#$i',
          'zoneCode': zoneCode,
          'zoneLabel': zoneLabel,
          'eventDate': event.date.toUtc(),
          'eventTitle': event.title,
          'imageUrl': event.imageUrl,
          'eventLocation': event.location,
          'unitPrice': unitPrice,
        });
      }
    });

    return orderRef.id;
  }

  Future<List<Map<String, dynamic>>> userTicketsForEvent(String eventId) async {
    final user = _auth.currentUser; 
    if (user == null) return [];
    final snap = await _db.collection('tickets')
      .where('userId', isEqualTo: user.uid)
      .where('eventId', isEqualTo: eventId)
      .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
