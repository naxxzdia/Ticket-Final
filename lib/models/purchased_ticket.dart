import 'dart:convert';

class PurchasedTicket {
  final String id; // unique ticket instance id
  final String eventId;
  final String title;
  final String imageUrl;
  final String location;
  final DateTime eventDate;
  final String zoneCode;
  final String zoneLabel;
  final double unitPrice;
  final int quantity;
  final double total;
  final String orderId; // generated order reference
  final DateTime purchasedAt;
  final bool passed; // true if eventDate < now at load/update time

  PurchasedTicket({
    required this.id,
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.eventDate,
    required this.zoneCode,
    required this.zoneLabel,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    required this.orderId,
    required this.purchasedAt,
    required this.passed,
  });

  PurchasedTicket copyWith({bool? passed}) => PurchasedTicket(
        id: id,
        eventId: eventId,
        title: title,
        imageUrl: imageUrl,
        location: location,
        eventDate: eventDate,
        zoneCode: zoneCode,
        zoneLabel: zoneLabel,
        unitPrice: unitPrice,
        quantity: quantity,
        total: total,
        orderId: orderId,
        purchasedAt: purchasedAt,
        passed: passed ?? this.passed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'title': title,
        'imageUrl': imageUrl,
        'location': location,
        'eventDate': eventDate.toIso8601String(),
        'zoneCode': zoneCode,
        'zoneLabel': zoneLabel,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'total': total,
        'orderId': orderId,
        'purchasedAt': purchasedAt.toIso8601String(),
        'passed': passed,
      };

  static PurchasedTicket fromJson(Map<String, dynamic> json) => PurchasedTicket(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String,
        location: json['location'] as String,
        eventDate: DateTime.parse(json['eventDate'] as String),
        zoneCode: json['zoneCode'] as String,
        zoneLabel: json['zoneLabel'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
        total: (json['total'] as num).toDouble(),
        orderId: json['orderId'] as String,
        purchasedAt: DateTime.parse(json['purchasedAt'] as String),
        passed: json['passed'] as bool? ?? false,
      );

  static List<PurchasedTicket> decodeList(String raw) {
    if (raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<PurchasedTicket> tickets) => jsonEncode(tickets.map((e) => e.toJson()).toList());
}
