// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:teftef/services/api_service.dart';
import 'package:teftef/core/config.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _isMoreLoading = false;
  List<dynamic> _products = [];
  String? _errorMessage;
  
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isMoreLoading &&
        _currentPage < _totalPages) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadInitialProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    final response = await ApiService.fetchMyProducts(page: 1);

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _products = response['data'] ?? [];
          _totalPages = int.tryParse(response['pagination']?['totalPages']?.toString() ?? '1') ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    setState(() => _isMoreLoading = true);
    
    final nextPage = _currentPage + 1;
    final response = await ApiService.fetchMyProducts(page: nextPage);

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _products.addAll(response['data'] ?? []);
          _currentPage = nextPage;
          _isMoreLoading = false;
        });
      } else {
        setState(() => _isMoreLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("My Products", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _products.isEmpty
                  ? _buildEmptyState()
                  : _buildProductList(),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadInitialProducts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _products.length + (_isMoreLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildProductCard(_products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final images = product['images'] as List<dynamic>?;
    String? imageUrl = images != null && images.isNotEmpty 
        ? AppConfig.getImageUrl(images[0].toString()) 
        : null;
    
    final bool isBoosted = product['isBoosted'] == true;
    final boostRequest = product['boostRequest'];
    final String? boostStatus = boostRequest?['status']?.toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isBoosted 
            ? Border.all(color: const Color(0xFFFF9800).withOpacity(0.3), width: 2)
            : Border.all(color: Colors.white, width: 2), // Keep layout stable
        boxShadow: [
          BoxShadow(
            color: isBoosted 
                ? const Color(0xFFFF9800).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Product Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
              child: SizedBox(
                width: 120,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : Container(color: Colors.grey[100], child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            // Right: Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? 'Unnamed Product',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBoostBadge(product),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ETB ${product['price']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4D3E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (boostStatus != 'pending' && !isBoosted) 
                          _buildActionButton(
                            icon: Icons.rocket_launch_rounded,
                            color: const Color(0xFFFF9800),
                            label: "Boost",
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context, 
                                '/boost_product', 
                                arguments: product,
                              );
                              if (result == true) _loadInitialProducts();
                            },
                          ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: Colors.blue[600]!,
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                                context, 
                                '/edit_product', 
                                arguments: product,
                            );
                            if (result == true) _loadInitialProducts();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red[500]!,
                          onPressed: () => _showDeleteConfirmation(product),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label != null ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(dynamic product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteProduct(product['id']);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService.deleteProduct(productId);
      
      // Close loading indicator
      Navigator.pop(context);

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        _loadInitialProducts(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to delete product')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Widget _buildBoostBadge(dynamic product) {
    final bool isBoosted = product['isBoosted'] == true;
    final boostRequest = product['boostRequest'];
    final String? boostStatus = boostRequest?['status']?.toString().toLowerCase();
    
    // 1. Check if ACTIVE
    if (isBoosted) {
      String expiryText = "PROMOTED";
      if (product['boostExpiresAt'] != null) {
        try {
          final expiry = DateTime.parse(product['boostExpiresAt'].toString());
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          expiryText = "Until ${months[expiry.month - 1]} ${expiry.day}";
        } catch (_) {}
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50), // Green for Active
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 10),
            const SizedBox(width: 4),
            Text(
              expiryText.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    // 2. Check if PENDING
    if (boostStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300), // Amber for Pending
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: const Text(
          "REVIEWING BOOST...",
          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      );
    }

    // 3. Check if REJECTED
    if (boostStatus == 'rejected') {
      return GestureDetector(
        onTap: () => _showRejectionReason(boostRequest['rejectionReason'] ?? "No reason provided by admin."),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935), // Red for Rejected
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "BOOST FAILED",
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              SizedBox(width: 4),
              Icon(Icons.help_outline_rounded, color: Colors.white, size: 10),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showRejectionReason(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text("Boost Rejected", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your payment verification was rejected for the following reason:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Text(
                reason,
                style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No products yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("You haven't posted any products for sale.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? "Failed to load products"),
          TextButton(onPressed: _loadInitialProducts, child: const Text("Retry")),
        ],
      ),
    );
  }
}
