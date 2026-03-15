import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/models.dart';
import '../../core/services/search_service.dart';

class ShopDetailView extends StatefulWidget {
  final String shopId;

  const ShopDetailView({super.key, required this.shopId});

  @override
  State<ShopDetailView> createState() => _ShopDetailViewState();
}

class _ShopDetailViewState extends State<ShopDetailView> {
  final SearchService _searchService = SearchService();
  bool _isLoading = true;
  ShopDetailsResponse? _details;
  bool _isOpen = false;
  String _closingSoonText = "";

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await _searchService.getShopDetailsById(widget.shopId);
      setState(() {
        _details = details;
        _isLoading = false;
        
        // Pre-calculate status to avoid expensive work in build()
        _isOpen = _isShopOpen(details.shop.openingTime, details.shop.closingTime);
        if (_isOpen) {
          _closingSoonText = _getClosingSoonText(details.shop.closingTime);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shop details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_details == null) {
      return const Scaffold(body: Center(child: Text("Shop details not found")));
    }

    final shop = _details!.shop;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(shop, _isOpen),
          _buildInfoSection(shop, _isOpen),
          _buildPhotosSection(shop),
          _buildReviewsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Shop shop, bool isOpen) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: shop.imageUrls.isNotEmpty
            ? Image.network(
                shop.imageUrls[0], 
                fit: BoxFit.cover,
                cacheWidth: 800, // Optimize memory
              )
            : Container(
                color: Colors.blue.shade900,
                child: const Icon(Icons.store, size: 80, color: Colors.white54),
              ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildInfoSection(Shop shop, bool isOpen) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOpen ? "OPEN" : "CLOSED",
                    style: TextStyle(
                      color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 16, color: Colors.blueGrey.shade400),
                const SizedBox(width: 6),
                Text(
                  "${shop.openingTime} - ${shop.closingTime}",
                  style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                if (_isOpen && _closingSoonText.isNotEmpty)
                  Text(
                    _closingSoonText,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              shop.description,
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection(Shop shop) {
    if (shop.imageUrls.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: shop.imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(shop.imageUrls[index]), 
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }


  Widget _buildReviewsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(_details!.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._details!.reviews.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 12, color: i < r.rating ? Colors.amber : Colors.grey.shade300)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.comment, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  bool _isShopOpen(String opening, String closing) {
    try {
      final now = DateTime.now();
      final openParts = opening.split(':').map(int.parse).toList();
      final closeParts = closing.split(':').map(int.parse).toList();
      
      final openTime = DateTime(now.year, now.month, now.day, openParts[0], openParts[1]);
      final closeTime = DateTime(now.year, now.month, now.day, closeParts[0], closeParts[1]);
      
      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (_) {
      return true;
    }
  }

  String _getClosingSoonText(String closing) {
    try {
      final now = DateTime.now();
      final closeParts = closing.split(':').map(int.parse).toList();
      final closeTime = DateTime(now.year, now.month, now.day, closeParts[0], closeParts[1]);
      
      final diff = closeTime.difference(now).inMinutes;
      if (diff > 0 && diff <= 60) {
        return "Closes in $diff mins";
      }
    } catch (_) {}
    return "";
  }
}
