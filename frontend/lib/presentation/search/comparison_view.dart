import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/search_service.dart';
import '../../domain/entities/models.dart';
import 'package:shimmer/shimmer.dart';

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
                  onPressed: () {},
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
                _buildFeaturedCard("Daily Essentials", "Fresh milk, bread & eggs", Colors.blue, Icons.breakfast_dining_rounded),
                _buildFeaturedCard("Smart Snacks", "High protein & organic", Colors.orange, Icons.cookie_rounded),
                _buildFeaturedCard("Home Care", "Cleaning & laundry", Colors.purple, Icons.home_repair_service_rounded),
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

  Widget _buildFeaturedCard(String title, String subtitle, Color color, IconData icon) {
    return Container(
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
                onPressed: () => _performSearch(_searchController.text),
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
                onTap: () {},
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
                                Text(
                                  offer.shopName,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                    Text(
                                      "${offer.distance.toStringAsFixed(1)} KM · Bangalore",
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
