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

  ShopOffer({
    required this.shopId,
    required this.shopName,
    required this.distance,
    required this.totalPrice,
    required this.itemsFound,
    required this.itemsOutOfStock,
    required this.foundItems,
    required this.missingItems,
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
