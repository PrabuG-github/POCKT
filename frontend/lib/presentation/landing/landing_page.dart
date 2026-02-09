import 'package:flutter/material.dart';
import '../search/comparison_view.dart';
import '../dashboard/shop_dashboard.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.5, 0.9],
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF0F172A), // Slate 900
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.adjust_rounded,
                  size: 120,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 30),
                const Text(
                  "POCKT",
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "SMART LOCAL SEARCH",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Spacer(),
                _buildRoleButton(
                  context,
                  title: "Find Best Deals",
                  subtitle: "Search local shops near you",
                  icon: Icons.search,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComparisonView()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildRoleButton(
                  context,
                  title: "Manage My Store",
                  subtitle: "Open orders & Inventory",
                  icon: Icons.storefront,
                  isSecondary: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopDashboard()),
                  ),
                ),
                const Spacer(),
                const Text(
                  "Powered by Beast.Inc",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSecondary
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue 500 to 600
        ),
        border: Border.all(
          color: isSecondary ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isSecondary ? Colors.black.withOpacity(0.2) : const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSecondary ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
