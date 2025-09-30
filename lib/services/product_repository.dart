import '../models/product.dart';
import 'api_client.dart';

class ProductRepository {
  final ApiClient api;
  ProductRepository(this.api);

  Future<List<Product>> fetchProducts() async {
    final list = await api.getJsonList('/products');
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> fetchProduct(int id) async {
    final json = await api.getJsonObject('/products/$id');
    return Product.fromJson(json);
  }
}
