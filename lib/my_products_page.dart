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
    final status = product['status']?.toString() ?? 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Product Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 130,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.broken_image, color: Colors.grey)
                                  ),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.image, color: Colors.grey)
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          _buildStatusBadge(status),
                          if (product['isBoosted'] == true) ...[
                            const SizedBox(width: 8),
                            _buildBoostedBadge(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right: Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Unnamed Product',
                      style: const TextStyle(
                        fontSize: 17, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ETB ${product['price']}",
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.rocket_launch_rounded,
                          color: const Color(0xFFFF9800),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context, 
                              '/boost_product', 
                              arguments: product,
                            );
                            if (result == true) {
                              _loadInitialProducts();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: Colors.blue[700]!,
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context, 
                              '/edit_product', 
                              arguments: product,
                            );
                            if (result == true) {
                              _loadInitialProducts();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red[600]!,
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
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 22),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF4CAF50);
        break;
      case 'draft':
        color = const Color(0xFFFF9800);
        break;
      case 'pending':
        color = const Color(0xFF2196F3);
        break;
      default:
        color = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 9, 
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBoostedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800), // Vibrant orange
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 10),
          const SizedBox(width: 4),
          const Text(
            "BOOSTED",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 9, 
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
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
