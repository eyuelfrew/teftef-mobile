import 'package:flutter/material.dart';
import 'package:teftef/utils/data_provider.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final Function(String) onSearch;
  final Function(String) onCategoryTap;

  const SearchSuggestionsWidget({
    super.key,
    required this.onSearch,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final recentSearches = [
      "Electronics",
      "Fashion",
      "Home",
      "Books",
      "Smart Watch",
      "Sneakers"
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Searches",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                labelStyle: const TextStyle(color: Colors.black),
                backgroundColor: Colors.grey[100],
                onPressed: () {
                  onSearch(search);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            "Popular Categories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: DataProvider.getCategories().map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      onCategoryTap(category.name);
                    },
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(category.image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}