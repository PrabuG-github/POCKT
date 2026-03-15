class BasketItem {
  final String productId;
  final String name;
  final int quantity;

  BasketItem({
    required this.productId,
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'quantity': quantity,
      };
}

class ShopItem {
  final String name;
  final double price;
  final int quantity;
  final double totalPrice;

  ShopItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      name: json['name'] ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}

class ShopOffer {
  final String shopId;
  final String shopName;
  final double distance;
  final double totalPrice;
  final int itemsFound;
  final int itemsOutOfStock;
  final List<ShopItem> foundItems;
  final List<String> missingItems;
  final double lat;
  final double lng;
  final String buildingNumber;
  final String address;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final double rating;
  final int reviewCount;

  ShopOffer({
    required this.shopId,
    required this.shopName,
    required this.distance,
    required this.totalPrice,
    required this.itemsFound,
    required this.itemsOutOfStock,
    required this.foundItems,
    required this.missingItems,
    required this.lat,
    required this.lng,
    required this.buildingNumber,
    required this.address,
    required this.pincode,
    required this.city,
    required this.state,
    required this.country,
    required this.rating,
    required this.reviewCount,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    return ShopOffer(
      shopId: json['shop_id'] ?? '',
      shopName: json['shop_name'] ?? '',
      distance: (json['distance'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      itemsFound: json['items_found'] ?? 0,
      itemsOutOfStock: json['items_out_of_stock'] ?? 0,
      foundItems: (json['found_items'] as List<dynamic>?)
              ?.map((e) => ShopItem.fromJson(e))
              .toList() ??
          [],
      missingItems: (json['missing_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      buildingNumber: json['building_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      rating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
    );
  }
}

class Review {
  final String id;
  final String shopId;
  final int rating;
  final String comment;
  final String username;
  final String createdAt;

  Review({
    required this.id,
    required this.shopId,
    required this.rating,
    required this.comment,
    required this.username,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      shopId: json['shop_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      username: json['username'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Shop {
  final String id;
  final String name;
  final String description;
  final String buildingNumber;
  final String address;
  final String pincode;
  final String city;
  final String state;
  final String country;
  final double lat;
  final double lng;
  final String openingTime;
  final String closingTime;
  final List<String> imageUrls;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    this.buildingNumber = '',
    required this.address,
    this.pincode = '',
    this.city = '',
    this.state = '',
    this.country = '',
    required this.lat,
    required this.lng,
    this.openingTime = '09:00',
    this.closingTime = '21:00',
    this.imageUrls = const [],
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      buildingNumber: json['building_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      openingTime: json['opening_time']?.toString() ?? '09:00',
      closingTime: json['closing_time']?.toString() ?? '21:00',
      imageUrls: (json['image_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'building_number': buildingNumber,
        'address': address,
        'pincode': pincode,
        'city': city,
        'state': state,
        'country': country,
        'lat': lat,
        'lng': lng,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'image_urls': imageUrls,
      };
}

class InventoryStats {
  final int totalItems;
  final int lowStockItems;
  final double totalValue;

  InventoryStats({
    required this.totalItems,
    required this.lowStockItems,
    required this.totalValue,
  });

  factory InventoryStats.fromJson(Map<String, dynamic> json) {
    return InventoryStats(
      totalItems: json['total_items'] ?? 0,
      lowStockItems: json['low_stock_items'] ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InventoryItem {
  final String productId;
  final String name;
  final double price;
  final String stockStatus;
  final String category;
  final String imageUrl;

  InventoryItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.stockStatus,
    required this.category,
    this.imageUrl = '',
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num).toDouble(),
      stockStatus: json['stock_status'] ?? 'in_stock',
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
class ShopDetailsResponse {
  final Shop shop;
  final List<InventoryItem> products;
  final List<Review> reviews;
  final double averageRating;
  final int reviewCount;

  ShopDetailsResponse({
    required this.shop,
    required this.products,
    required this.reviews,
    required this.averageRating,
    required this.reviewCount,
  });

  factory ShopDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ShopDetailsResponse(
      shop: Shop.fromJson(json['shop'] ?? {}),
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => InventoryItem.fromJson(e))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e))
              .toList() ??
          [],
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
    );
  }
}
