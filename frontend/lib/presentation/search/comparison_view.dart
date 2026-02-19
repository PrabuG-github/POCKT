import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/search_service.dart';
import '../../domain/entities/models.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ComparisonView extends StatefulWidget {
  final List<ShopOffer>? initialOffers;
  final List<BasketItem>? initialBasket;

  const ComparisonView({super.key, this.initialOffers, this.initialBasket});

  @override
  _ComparisonViewState createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  double _radius = 3.0;
  bool _isMapView = false;
  final SearchService _searchService = SearchService();
  List<ShopOffer> _offers = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _radius = _searchService.preferredRadius;
    
    if (widget.initialOffers != null) {
      _offers = widget.initialOffers!;
      // Do not auto-search if results provided
    } else {
      _performSearch(""); 
    }
  }

  Future<void> _performSearch(String query) async {
    print('ComparisonView: Performing search for "$query"');
    if (query.isEmpty) {
      setState(() {
        _offers = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    // For now, we treat the search query as a single item in our basket for testing
    final results = await _searchService.aggregatePrices(
      items: [
        BasketItem(productId: 'search_query', name: query, quantity: 1),
      ],
      radiusKm: _radius,
      userLat: 12.9716, // Default to Bangalore coords or similar for testing
      userLong: 77.5946,
    );

    print('ComparisonView: Found ${results.length} offers for "$query" at radius $_radius');

    setState(() {
      _offers = results;
      _isLoading = false;
    });
  }

  Future<void> _launchMap(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map')),
      );
    }
  }

  void _showProductDetails(ShopOffer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const TabBar(
                    tabs: [
                      Tab(text: "Products"),
                      Tab(text: "Reviews"),
                    ],
                    labelColor: Color(0xFF2563EB),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF2563EB),
                    labelStyle: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildProductTab(offer, scrollController),
                        _buildReviewTab(offer, scrollController, () => setSheetState(() {})),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductTab(ShopOffer offer, ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.store_rounded, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.shopName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      "${offer.buildingNumber}, ${offer.address}, ${offer.city}",
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.directions_rounded, color: Color(0xFF3B82F6)),
                onPressed: () => _launchMap(offer.lat, offer.lng),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            "Available Products",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: offer.foundItems.length,
              itemBuilder: (context, index) {
                final item = offer.foundItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            "Unit Price: ₹${item.price.toStringAsFixed(0)}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        "₹${item.totalPrice.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (offer.missingItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Not Available Here",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: offer.missingItems.map((item) => Chip(
                label: Text(item, style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626))),
                backgroundColor: const Color(0xFFFEF2F2),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTab(ShopOffer offer, ScrollController scrollController, VoidCallback onRefresh) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SearchService().getShopDetails(offer.shopId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final shopData = snapshot.data!;
        final reviews = (shopData['reviews'] as List)
            .map((e) => Review.fromJson(e))
            .toList();
        
        // Use updated rating from API if available
        final currentRating = (shopData['average_rating'] as num?)?.toDouble() ?? offer.rating;
        final currentReviewCount = shopData['review_count'] ?? offer.reviewCount;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            _buildReviewStats(currentRating, currentReviewCount),
            const SizedBox(height: 24),
            _buildAddReviewSection(offer, onRefresh),
            const SizedBox(height: 32),
            const Text("Customer Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (reviews.isEmpty)
              const Center(child: Text("No reviews yet. Be the first!"))
            else
              ...reviews.map((r) => _buildReviewItem(r)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildReviewStats(double rating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: i < rating.floor() ? Colors.amber : Colors.grey.shade300,
                )),
              ),
              const SizedBox(height: 4),
              Text("$reviewCount Reviews", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.rate_review_rounded, size: 48, color: Color(0xFFE2E8F0)),
        ],
      ),
    );
  }

  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  Widget _buildAddReviewSection(ShopOffer offer, VoidCallback onRefresh) {
    return StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rate this Store", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => IconButton(
              icon: Icon(
                i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () => setState(() => _selectedRating = i + 1),
            )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            decoration: InputDecoration(
              hintText: "Add a comment...",
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_reviewController.text.isEmpty) return;
                await SearchService().addReview(offer.shopId, _selectedRating, _reviewController.text);
                _reviewController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review added!")));
                onRefresh(); // Refresh the tab content
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Submit Review"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(review.username, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(review.createdAt, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) => Icon(
              Icons.star_rounded,
              size: 14,
              color: i < review.rating ? Colors.amber : Colors.grey.shade300,
            )),
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(color: Color(0xFF475569))),
        ],
      ),
    );
  }

  void _showAllCategories() {
    final categories = ["Daily Essentials", "Smart Snacks", "Home Care", "Beverages", "Personal Care", "Stationery"];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("All Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) => InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _searchController.text = cat;
                  _performSearch(cat);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sort Results", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildFilterOption("Lowest Price", Icons.payments_rounded, () {
              setState(() {
                _offers.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
              });
              Navigator.pop(context);
            }),
            _buildFilterOption("Nearest Store", Icons.near_me_rounded, () {
              setState(() {
                _offers.sort((a, b) => a.distance.compareTo(b.distance));
              });
              Navigator.pop(context);
            }),
            _buildFilterOption("Relevance", Icons.star_rounded, () {
              _performSearch(_searchController.text);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3B82F6)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildSearchHeader(),
          ),
          SliverFillRemaining(
            child: _isLoading
                ? _buildShimmerList()
                : _offers.isEmpty
                    ? _buildEmptyState()
                    : (_isMapView ? _buildMapView() : _buildListView()),
          ),
        ],
      ),
      bottomNavigationBar: _buildRadiusSlider(),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Featured Collections",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                TextButton(
                  onPressed: _showAllCategories,
                  child: const Text("View All", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildFeaturedCard("Daily Essentials", "Fresh milk, bread & eggs", Colors.blue, Icons.breakfast_dining_rounded, () {
                  _searchController.text = "Daily Essentials";
                  _performSearch("Daily Essentials");
                }),
                _buildFeaturedCard("Smart Snacks", "High protein & organic", Colors.orange, Icons.cookie_rounded, () {
                  _searchController.text = "Snacks";
                  _performSearch("Snacks");
                }),
                _buildFeaturedCard("Home Care", "Cleaning & laundry", Colors.purple, Icons.home_repair_service_rounded, () {
                  _searchController.text = "Home Care";
                  _performSearch("Home Care");
                }),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "NEW FEATURE",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Smart Comparison\nEngine v2.0",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We now compare prices across 50+ local stores in your area within seconds.",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(String title, String subtitle, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 160,
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "Marketplace",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isMapView ? Icons.list_alt_rounded : Icons.map_rounded, color: Colors.white),
          onPressed: () => setState(() => _isMapView = !_isMapView),
        )
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (val) => _performSearch(val),
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "What are you looking for today?",
            hintStyle: TextStyle(color: Colors.blueGrey.shade400),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                onPressed: _showFilterDialog,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = _offers[index];
        final bool isBestPrice = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isBestPrice ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              if (isBestPrice)
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showProductDetails(offer),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isBestPrice ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              color: isBestPrice ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                  offer.foundItems.isNotEmpty 
                                    ? offer.foundItems.map((e) => e.name).join(", ") 
                                    : offer.shopName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      offer.shopName,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      offer.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      " (${offer.reviewCount})",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                if (offer.missingItems.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Missing: ${offer.missingItems.join(', ')}",
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${offer.distance.toStringAsFixed(1)} KM · ${offer.buildingNumber}${offer.buildingNumber.isNotEmpty ? ', ' : ''}${offer.address}${offer.city.isNotEmpty ? ', ' : ''}${offer.city}",
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${offer.totalPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isBestPrice ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                ),
                              ),
                              if (isBestPrice)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "BEST VALUE",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.directions_rounded, size: 24, color: Color(0xFF3B82F6)),
                            onPressed: () => _launchMap(offer.lat, offer.lng),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: Colors.blueGrey.shade100),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${offer.itemsFound} ITEMS MATCHED",
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (offer.itemsOutOfStock > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${offer.itemsOutOfStock} OOS",
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              children: const [
                                Text(
                                  "View Basket",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF3B82F6)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 15),
            Text(
              "Interactive Map View",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            Text("Found ${_offers.length} shops within ${_radius == 0 ? 'All' : _radius.toStringAsFixed(1) + 'km'}", 
                 style: TextStyle(color: Colors.blue.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 20, bottom: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Search Radius (0 = Infinite)", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                _radius == 0 ? "Infinite" : "${_radius.toStringAsFixed(1)}km",
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue.shade900,
              inactiveTrackColor: Colors.blue.shade50,
              thumbColor: Colors.blue.shade900,
              overlayColor: Colors.blue.withOpacity(0.1),
            ),
            child: Slider(
              value: _radius,
              min: 0.0,
              max: 10.0,
              onChanged: (val) {
                setState(() {
                  _radius = val;
                  _searchService.preferredRadius = val; // Persist change
                });
              },
              onChangeEnd: (val) => _performSearch(_searchController.text),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}
