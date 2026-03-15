import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/models.dart';

class SearchService {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  // Singleton instance
  static final SearchService _instance = SearchService._internal();

  factory SearchService() {
    return _instance;
  }

  SearchService._internal();

  // Persistent search state
  double preferredRadius = 3.0;

  Future<List<ShopOffer>> aggregatePrices({
    required List<BasketItem> items,
    required double radiusKm,
    required double userLat,
    required double userLong,
  }) async {
    final url = '$_baseUrl/api/aggregate';
    final body = jsonEncode({
      'items': items.map((e) => e.toJson()).toList(),
      'radius_km': radiusKm,
      'user_lat': userLat,
      'user_long': userLong,
    });

    print('SearchService: Calling API $url');
    print('SearchService: Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('SearchService: Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('SearchService: Successfully received ${data.length} offers');
        return data.map((json) => ShopOffer.fromJson(json)).toList();
      } else {
        print('SearchService: API Error - ${response.body}');
        throw Exception('Failed to load prices: ${response.statusCode}');
      }
    } catch (e) {
      print('SearchService: Exception calling API: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getShopDetails(String shopId) async {
    final url = '$_baseUrl/api/shop/details?id=$shopId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load shop details');
    } catch (e) {
      print('SearchService: Error fetching shop details: $e');
      rethrow;
    }
  }

  Future<ShopDetailsResponse> getShopDetailsById(String shopId) async {
    final url = '$_baseUrl/api/shop/details?id=$shopId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return ShopDetailsResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to load shop details');
    } catch (e) {
      print('SearchService: Error fetching shop details: $e');
      rethrow;
    }
  }

  Future<void> addReview(String shopId, int rating, String comment) async {
    final url = '$_baseUrl/api/shop/review';
    final body = jsonEncode({
      'shop_id': shopId,
      'rating': rating,
      'comment': comment,
      'username': 'Customer' // For now hardcoded
    });
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add review');
      }
    } catch (e) {
      print('SearchService: Error adding review: $e');
      rethrow;
    }
  }
}
