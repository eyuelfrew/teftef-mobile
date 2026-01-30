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
          _totalPages = response['pagination']?['totalPages'] ?? 1;
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                      : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 50)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed Product',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ETB ${product['price']}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
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
                            icon: const Icon(Icons.edit_note, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _showDeleteConfirmation(product),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
