import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/services/dashboard_service.dart';
import 'package:frontend/domain/entities/models.dart';
import 'package:shimmer/shimmer.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final DashboardService _dashboardService = DashboardService();
  List<InventoryItem> _inventory = [];
  bool _isLoading = true;
  String _shopName = "Loading...";
  Shop? _shop;
  InventoryStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadShopDetails(),
      _loadInventory(),
      _loadStats(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _dashboardService.fetchInventoryStats();
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> _loadShopDetails() async {
    try {
      final shop = await _dashboardService.fetchShopDetails();
      if (shop != null && mounted) {
        setState(() {
          _shop = shop;
          _shopName = shop.name;
        });
      }
    } catch (e) {
      print('Error fetching shop details: $e');
    }
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final items = await _dashboardService.fetchInventory();
      setState(() {
        _inventory = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
      }
    }
  }

  Future<void> _addProduct(String name, double price, String category, String imageUrl) async {
    try {
      final message = await _dashboardService.addProduct(
        name: name,
        price: price,
        category: category,
        imageUrl: imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        _loadInventory();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  Future<void> _toggleStockStatus(InventoryItem item) async {
    final newStatus = item.stockStatus == 'in_stock' ? 'out_of_stock' : 'in_stock';
    try {
      await _dashboardService.addProduct(
        name: item.name,
        price: item.price,
        category: item.category,
        stockStatus: newStatus,
      );
      _loadInventory();
      _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock status: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to remove this item from your inventory?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dashboardService.deleteProduct(productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product removed successfully')),
          );
          _loadInventory();
          _loadStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing product: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateProduct(String id, String name, double price, String category, String stockStatus, String imageUrl) async {
    try {
      await _dashboardService.updateProduct(
        productId: id,
        name: name,
        price: price,
        category: category,
        stockStatus: stockStatus,
        imageUrl: imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        _loadInventory();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        title: const Text(
          "Manager Console",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadInventory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPremiumHeader(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Quick Stats", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  _buildStatsGrid(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Product Inventory", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  _buildProductList(),
                ],
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 10,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "NEW PRODUCT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shopName,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              if (_shop != null)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showEditShopDialog(context);
                  },
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  tooltip: "Manage Profile",
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Top Rated Seller", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Ready for business!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.3,
        children: [
          _buildStatCard("Total Value", "₹${_stats?.totalValue.toStringAsFixed(0) ?? '0'}", Icons.monetization_on_rounded, Colors.green),
          _buildStatCard("Low Stock", "${_stats?.lowStockItems ?? 0}", Icons.warning_amber_rounded, Colors.orange),
          _buildStatCard("Total Items", "${_stats?.totalItems ?? 0}", Icons.inventory_2_rounded, Colors.blue),
          _buildStatCard("Profile Views", "0", Icons.remove_red_eye_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(3, (index) => _buildShimmerProductCard()),
        ),
      );
    }
    
    if (_inventory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text("No products in inventory", style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: _inventory.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _inventory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                    child: item.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                item.name.isNotEmpty ? item.name[0].toUpperCase() : "?",
                                style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            item.name.isNotEmpty ? item.name[0].toUpperCase() : "?",
                            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                        ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.category.toUpperCase()} · ₹${item.price.toStringAsFixed(0)}",
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _showEditProductDialog(context, item);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _deleteProduct(item.productId);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _toggleStockStatus(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: item.stockStatus == 'in_stock' ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.stockStatus == 'in_stock' ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.stockStatus == 'in_stock' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 14,
                          color: item.stockStatus == 'in_stock' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.stockStatus == 'in_stock' ? "STOCK" : "OOS",
                          style: TextStyle(
                            color: item.stockStatus == 'in_stock' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, List<String>>>(
        future: _dashboardService.fetchSuggestions(),
        builder: (context, snapshot) {
          final names = snapshot.data?['names'] ?? [];
          final categories = snapshot.data?['categories'] ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Add New Product"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return names.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      nameController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) => nameController.text = val,
                        decoration: InputDecoration(
                          labelText: "Product Name", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return categories.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      categoryController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) => categoryController.text = val,
                        decoration: InputDecoration(
                          labelText: "Category", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: "Price", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      labelText: "Image URL (Optional)", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text;
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  final category = categoryController.text;
                  final imageUrl = imageController.text;
                  
                  if (name.isNotEmpty && price > 0) {
                    Navigator.pop(context);
                    _addProduct(name, price, category, imageUrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid details')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900, 
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save Product"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, InventoryItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    final categoryController = TextEditingController(text: item.category);
    final imageController = TextEditingController(text: item.imageUrl);
    String currentStockStatus = item.stockStatus;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, List<String>>>(
        future: _dashboardService.fetchSuggestions(),
        builder: (context, snapshot) {
          final names = snapshot.data?['names'] ?? [];
          final categories = snapshot.data?['categories'] ?? [];

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final hasChanges = nameController.text != item.name ||
                  priceController.text != item.price.toStringAsFixed(0) ||
                  categoryController.text != item.category ||
                  imageController.text != item.imageUrl ||
                  currentStockStatus != item.stockStatus;

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text("Edit Product"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: item.name),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return names.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          nameController.text = selection;
                          setDialogState(() {});
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) {
                              nameController.text = val;
                              setDialogState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: "Product Name", 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: item.category),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return categories.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          categoryController.text = selection;
                          setDialogState(() {});
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) {
                              categoryController.text = val;
                              setDialogState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: "Category", 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: priceController,
                        onChanged: (val) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: "Price", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentStockStatus,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'in_stock', child: Text('In Stock')),
                              DropdownMenuItem(value: 'out_of_stock', child: Text('Out of Stock')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => currentStockStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: hasChanges ? () {
                      final name = nameController.text;
                      final price = double.tryParse(priceController.text) ?? 0.0;
                      final category = categoryController.text;
                      final imageUrl = imageController.text;
                      
                      if (name.isNotEmpty && price > 0) {
                        Navigator.pop(context);
                        _updateProduct(item.productId, name, price, category, currentStockStatus, imageUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter valid details')),
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasChanges ? Colors.blue.shade900 : Colors.grey.shade300, 
                      foregroundColor: hasChanges ? Colors.white : Colors.grey.shade600,
                    ),
                    child: const Text("Update Changes"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showEditShopDialog(BuildContext context) {
    if (_shop == null) return;

    final nameController = TextEditingController(text: _shop!.name);
    final buildingController = TextEditingController(text: _shop!.buildingNumber);
    final addressController = TextEditingController(text: _shop!.address);
    final pincodeController = TextEditingController(text: _shop!.pincode);
    final cityController = TextEditingController(text: _shop!.city);
    final stateController = TextEditingController(text: _shop!.state);
    final countryController = TextEditingController(text: _shop!.country);
    final descriptionController = TextEditingController(text: _shop!.description);
    final latController = TextEditingController(text: _shop!.lat.toString());
    final lngController = TextEditingController(text: _shop!.lng.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Shop Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController, 
                decoration: InputDecoration(
                  labelText: "Shop Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: buildingController, 
                decoration: InputDecoration(
                  labelText: "Building/Flat Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController, 
                decoration: InputDecoration(
                  labelText: "Street Address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pincodeController, 
                      decoration: InputDecoration(
                        labelText: "Pincode",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: cityController, 
                      decoration: InputDecoration(
                        labelText: "City",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stateController, 
                      decoration: InputDecoration(
                        labelText: "State",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: countryController, 
                      decoration: InputDecoration(
                        labelText: "Country",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController, 
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController, 
                      decoration: InputDecoration(
                        labelText: "Latitude",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ), 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: lngController, 
                      decoration: InputDecoration(
                        labelText: "Longitude",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ), 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _updateShopDetails(
                nameController.text,
                buildingController.text,
                addressController.text,
                pincodeController.text,
                cityController.text,
                stateController.text,
                countryController.text,
                descriptionController.text,
                double.tryParse(latController.text) ?? 0.0,
                double.tryParse(lngController.text) ?? 0.0,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateShopDetails(String name, String buildingNumber, String address, String pincode, String city, String state, String country, String description, double lat, double lng) async {
    if (_shop == null) return;
    
    final updatedShop = Shop(
      id: _shop!.id,
      name: name,
      buildingNumber: buildingNumber,
      address: address,
      pincode: pincode,
      city: city,
      state: state,
      country: country,
      description: description,
      lat: lat,
      lng: lng,
    );

    try {
      await _dashboardService.updateShop(updatedShop);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop profile updated successfully')),
        );
        _loadShopDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating shop profile: $e')),
        );
      }
    }
  }
  Widget _buildShimmerProductCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
