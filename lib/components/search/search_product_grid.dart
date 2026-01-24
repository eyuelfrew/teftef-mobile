import 'package:flutter/material.dart';
import 'package:teftef/models/product.dart';
import 'package:teftef/components/product_card.dart';

class SearchProductGrid extends StatelessWidget {
  final List<Product> products;
  final double width;
  final bool isGrid;

  const SearchProductGrid({
    super.key,
    required this.products,
    this.width = 160,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(
            product: products[index],
            width: width,
            isGrid: isGrid,
          );
        },
      ),
    );
  }
}