class Event {
  final String id;
  final String title;
  final String imageUrl;
  final String location;
  final DateTime date;
  final double price;
  final String category;
  final String description;
  // Optional per-zone pricing. Keys example: VVIP, VIP, REG
  final Map<String, double>? zonePrices;

  Event({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.price,
    required this.category,
    required this.description,
    this.zonePrices,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        location: json['location'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
        category: json['category'] ?? 'Other',
        description: json['description'] ?? '',
        zonePrices: (json['zonePrices'] is Map)
            ? (json['zonePrices'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'location': location,
        'date': date.toIso8601String(),
        'price': price,
        'category': category,
        'description': description,
    if (zonePrices != null) 'zonePrices': zonePrices,
      };
}
