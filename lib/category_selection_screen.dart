import 'package:flutter/material.dart';
import 'package:teftef/services/api_service.dart';
import 'package:teftef/post_product_page.dart';

class CategorySelectionScreen extends StatefulWidget {
  final List<dynamic>? subCategories;
  final String title;

  const CategorySelectionScreen({
    super.key, 
    this.subCategories, 
    this.title = "Select Category"
  });

  @override
  _CategorySelectionScreenState createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subCategories == null) {
      _fetchRootCategories();
    } else {
      setState(() {
        _categories = widget.subCategories!;
      });
    }
  }

  Future<void> _fetchRootCategories() async {
    setState(() => _isLoading = true);
    final cats = await ApiService.fetchCategoryTree();
    if (cats.isNotEmpty) {
    }
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  void _handleCategoryTap(dynamic category) {
    if (category['children'] != null && (category['children'] as List).isNotEmpty) {
      // Drill down
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategorySelectionScreen(
            subCategories: category['children'],
            title: category['name'],
          ),
        ),
      );
    } else {
      // Leaf node - Go to Post Form
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostProductPage(selectedCategory: category),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 50, 50, 50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 50, 50, 50),
              ),
            )
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No categories found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, index) {
                    final cat = _categories[index];
                    final hasChildren = cat['children'] != null && (cat['children'] as List).isNotEmpty;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleCategoryTap(cat),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              // Category Image
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: cat['image'] != null && cat['image'].toString().isNotEmpty
                                      ? Image.network(
                                          cat['image'].toString(),
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.category_outlined,
                                                color: Colors.grey[400],
                                                size: 24,
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: const Color.fromARGB(255, 50, 50, 50),
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.category_outlined,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Category Name
                              Expanded(
                                child: Text(
                                  cat['name'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C2C2C),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              // Arrow or Badge
                              if (hasChildren)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 50, 50, 50).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Color.fromARGB(255, 50, 50, 50),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Select',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
