import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/product_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final int id;
  final Product? initialProduct;
  const ProductDetailScreen({super.key, required this.id, this.initialProduct});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductRepository _repo = ProductRepository(ApiClient());
  Product? product;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    product = widget.initialProduct;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await _repo.fetchProduct(widget.id);
      setState(() {
        product = p;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(p?.name ?? 'Product'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                    ],
                  ),
                )
              : p == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.headphones, size: 120, color: Colors.black54),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                          Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text(p.detail, style: const TextStyle(fontSize: 14, height: 1.4)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: p.available ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text(p.available ? 'Available' : 'Unavailable'),
                          ],
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          onPressed: p.available ? () {} : null,
                          child: const Text('ADD TO CART'),
                        )
                      ],
                    ),
    );
  }
}
