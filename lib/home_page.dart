import 'package:flutter/material.dart';
import 'package:teftef/components/product_card.dart';
import 'package:teftef/utils/data_provider.dart';
import 'package:teftef/services/api_service.dart';
import 'package:teftef/models/product.dart';
import 'dart:developer' show log;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  List<dynamic> _allProducts = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.fetchProducts(page: 1, limit: 10);
      if (response['success'] == true) {
        setState(() {
          _allProducts = response['data'] ?? [];
          _currentPage = response['pagination']?['currentPage'] ?? 1;
          _totalPages = response['pagination']?['totalPages'] ?? 1;
          _hasMoreProducts = _currentPage < _totalPages;
          _isLoading = false;
        });
        log('Loaded initial products: ${_allProducts.length}');
      } else {
        log('Failed to load products: ${response['message']}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      log('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMoreProducts) return;

    setState(() => _isLoading = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.fetchProducts(page: nextPage, limit: 10);
      
      if (response['success'] == true) {
        setState(() {
          _allProducts.addAll(response['data'] ?? []);
          _currentPage = response['pagination']?['currentPage'] ?? nextPage;
          _totalPages = response['pagination']?['totalPages'] ?? _totalPages;
          _hasMoreProducts = _currentPage < _totalPages;
          _isLoading = false;
        });
        log('Loaded more products. Total: ${_allProducts.length}');
      } else {
        log('Failed to load more products: ${response['message']}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      log('Error loading more products: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreProducts();
    }
  }

  /// Build full image URL from relative path
  String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'assets/placeholder.png';
    }
    
    // If already a full URL, return as-is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Prepend base URL to relative path
    return 'http://localhost:5000$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    final categories = DataProvider.getCategories();
    final featuredProducts = DataProvider.getProducts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Tef",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              " Tef",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/search');
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Categories horizontal scroll
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    IconData categoryIcon;
                    switch (categories[index].name.toLowerCase()) {
                      case 'electronics':
                        categoryIcon = Icons.devices;
                        break;
                      case 'fashion':
                        categoryIcon = Icons.checkroom;
                        break;
                      case 'home':
                        categoryIcon = Icons.home;
                        break;
                      case 'books':
                        categoryIcon = Icons.menu_book;
                        break;
                      case 'sports':
                        categoryIcon = Icons.sports;
                        break;
                      case 'beauty':
                        categoryIcon = Icons.face_retouching_natural;
                        break;
                      default:
                        categoryIcon = Icons.category;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/category', arguments: categories[index].name);
                        },
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                categoryIcon,
                                size: 32,
                                color: Colors.black,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                categories[index].name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Featured Products title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Featured Products",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/category');
                    },
                    child: const Text(
                      "See All",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Featured Products horizontal scroll
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: featuredProducts[index],
                      width: 150,
                      isGrid: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // All Products title
              const Text(
                "All Products",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // All Products with infinite scroll
              _allProducts.isEmpty && !_isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No products available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,  // Adjusted for taller cards
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _allProducts.length + (_hasMoreProducts ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Loading indicator at the end
                        if (index == _allProducts.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            ),
                          );
                        }

                        final product = _allProducts[index];
                        
                        // Convert API product to Product model if needed
                        final productModel = product is Product
                            ? product
                            : Product(
                                name: product['name'] ?? 'Unknown',
                                description: product['description'] ?? '',
                                price: double.tryParse(product['price']?.toString() ?? '0') ?? 0.0,
                                category: product['category'] ?? 'General',
                                image: _buildImageUrl(product['images']?[0]),
                              );

                        return ProductCard(
                          product: productModel,
                          width: double.infinity,
                          isGrid: true,
                        );
                      },
                    ),

              // Loading indicator at bottom
              if (_isLoading && _allProducts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}