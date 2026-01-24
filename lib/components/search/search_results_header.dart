import 'package:flutter/material.dart';

class SearchResultsHeader extends StatelessWidget {
  final int resultCount;
  final String query;
  final Function(String) onSortSelected;

  const SearchResultsHeader({
    super.key,
    required this.resultCount,
    required this.query,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$resultCount results for '$query'",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: onSortSelected,
            child: const Icon(Icons.sort, color: Colors.black),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Text('Sort by Category'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}