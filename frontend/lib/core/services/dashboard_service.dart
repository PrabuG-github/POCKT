import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/domain/entities/models.dart';


class DashboardService {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<String> addProduct({
    required String name,
    required double price,
    required String category,
    String stockStatus = 'in_stock',
    String imageUrl = '',
  }) async {
    final url = '$_baseUrl/api/products';
    final body = jsonEncode({
      'name': name,
      'price': price,
      'category': category,
      'stock_status': stockStatus,
      'image_url': imageUrl,
    });

    print('DashboardService: Calling API $url');
    print('DashboardService: Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('DashboardService: Response Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Product processed successfully';
      } else {
        print('DashboardService: API Error - ${response.body}');
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Exception calling API: $e');
      rethrow;
    }
  }

  Future<List<InventoryItem>> fetchInventory() async {
    final url = '$_baseUrl/api/inventory';
    print('DashboardService: Calling API $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('DashboardService: Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('DashboardService: Successfully received ${data.length} inventory items');
        return data.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        print('DashboardService: API Error - ${response.body}');
        throw Exception('Failed to fetch inventory: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Exception calling API: $e');
      return [];
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required double price,
    required String category,
    required String stockStatus,
    String imageUrl = '',
  }) async {
    final url = '$_baseUrl/api/products/update';
    final body = jsonEncode({
      'product_id': productId,
      'name': name,
      'price': price,
      'category': category,
      'stock_status': stockStatus,
      'image_url': imageUrl,
    });

    print('DashboardService: Calling API $url');
    print('DashboardService: Request Body: $body');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('DashboardService: Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('DashboardService: API Error - ${response.body}');
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Exception calling API: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final url = '$_baseUrl/api/products/delete';
    final body = jsonEncode({'product_id': productId});

    print('DashboardService: Calling API $url');
    print('DashboardService: Request Body: $body');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('DashboardService: Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('DashboardService: API Error - ${response.body}');
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Exception calling API: $e');
      rethrow;
    }
  }

  Future<Map<String, List<String>>> fetchSuggestions() async {
    final url = '$_baseUrl/api/suggestions';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'names': List<String>.from(data['names'] ?? []),
          'categories': List<String>.from(data['categories'] ?? []),
        };
      }
      return {'names': [], 'categories': []};
    } catch (e) {
      print('DashboardService: Error fetching suggestions: $e');
      return {'names': [], 'categories': []};
    }
  }

  Future<Shop?> fetchShopDetails() async {
    final url = '$_baseUrl/api/shop';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return Shop.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('DashboardService: Error fetching shop details: $e');
      return null;
    }
  }

  Future<void> updateShop(Shop shop) async {
    final url = '$_baseUrl/api/shop/update';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(shop.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update shop details: ${response.statusCode}');
      }
    } catch (e) {
      print('DashboardService: Error updating shop details: $e');
      rethrow;
    }
  }

  Future<InventoryStats?> fetchInventoryStats() async {
    final url = '$_baseUrl/api/inventory/stats';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return InventoryStats.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('DashboardService: Error fetching inventory stats: $e');
      return null;
    }
  }
}
