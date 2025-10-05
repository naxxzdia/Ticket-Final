class OrderDoc {
  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String eventLocation;
  final String? imageUrl; // removed from Firestore writes; keep nullable for backward compatibility
  final String zoneCode;
  final String zoneLabel;
  final double unitPrice;
  final int quantity;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime? paidAt;

  OrderDoc({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    this.imageUrl,
    required this.zoneCode,
    required this.zoneLabel,
    required this.unitPrice,
    required this.quantity,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.paidAt,
  });

  factory OrderDoc.fromMap(String id, Map<String, dynamic> map) {
    DateTime _ts(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      // Firestore Timestamp: detect via toString() pattern (defensive for loosely typed maps)
      if (v.toString().contains('Timestamp')) {
        try { return v.toDate(); } catch (_) {}
      }
      return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    double _d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

    return OrderDoc(
      id: id,
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      eventDate: _ts(map['eventDate']),
      eventLocation: map['eventLocation'] ?? '',
  imageUrl: map['imageUrl'] as String?,
      zoneCode: map['zoneCode'] ?? '',
      zoneLabel: map['zoneLabel'] ?? '',
      unitPrice: _d(map['unitPrice']),
      quantity: (map['quantity'] is int) ? map['quantity'] as int : int.tryParse(map['quantity'].toString()) ?? 0,
      totalAmount: _d(map['totalAmount']),
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? 'unknown',
      paidAt: map['paidAt'] == null ? null : _ts(map['paidAt']),
    );
  }
}
