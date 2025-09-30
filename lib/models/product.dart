class Product {
  final int id;
  final String name;
  final double price;
  final String detail;
  final String? imageUrl;
  final bool available;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.detail,
    this.imageUrl,
    this.available = true,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] is String) ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0) as int,
        name: json['name'] ?? '',
        price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price'].toString()) ?? 0.0,
        detail: json['detail'] ?? json['description'] ?? '',
        imageUrl: json['imageUrl'] ?? json['image'] as String?,
        available: json['available'] ?? json['isAvailable'] ?? true,
        category: json['category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'detail': detail,
        'imageUrl': imageUrl,
        'available': available,
        'category': category,
      };
}
