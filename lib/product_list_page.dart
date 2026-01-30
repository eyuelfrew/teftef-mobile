import 'package:flutter/material.dart';
import 'package:teftef/components/product_card.dart';
import 'package:teftef/utils/data_provider.dart';
import 'package:teftef/models/product.dart';

class ProductListPage extends StatelessWidget {
  final String? category;

  const ProductListPage({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    // Filter products by category if provided
    List<Product> filteredProducts = category != null
        ? DataProvider.getProductsByCategory(category!)
        : DataProvider.getProducts();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category ?? "All Products",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search in ${category ?? "All Products"}...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Products count
            Text(
              "${filteredProducts.length} products found",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Products list
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,  // Adjusted for taller cards
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: filteredProducts[index],
                    width: 160,
                    isGrid: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}