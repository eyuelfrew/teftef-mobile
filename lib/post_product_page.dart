import 'package:flutter/material.dart';
import 'package:teftef/services/api_service.dart';
import 'package:teftef/utils/image_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostProductPage extends StatefulWidget {
  final dynamic selectedCategory;
  
  const PostProductPage({super.key, required this.selectedCategory});

  @override
  _PostProductPageState createState() => _PostProductPageState();
}

class _PostProductPageState extends State<PostProductPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  // Product data
  final ProductData _productData = ProductData();

  // Dynamic Data
  List<dynamic> _attributes = [];
  Map<String, dynamic> _dynamicFormValues = {};

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _mainImage;
  final List<File> _additionalImages = [];

  @override
  void initState() {
    super.initState();
    _productData.category = widget.selectedCategory['name'];
    _fetchAttributes(widget.selectedCategory['id']);
  }

  Future<void> _fetchAttributes(int categoryId) async {
    setState(() => _isLoading = true);
    final attrs = await ApiService.fetchAttributes(categoryId);
    setState(() {
      _attributes = attrs;
      _dynamicFormValues = {}; // Reset form values
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 50, 50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          "Post Product",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 50, 50, 50),
            ),
          )
        : Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              // Form Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    if (_attributes.isNotEmpty) _buildDynamicAttributes(),
                    _buildBasicInfoStep(),
                    _buildFinalStep(),
                  ],
                ),
              ),
            ],
          ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressIndicator() {
    final maxPages = (_attributes.isNotEmpty ? 2 : 1);
    final totalSteps = maxPages + 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < _currentPage;
          final isCurrent = index == _currentPage;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? const Color.fromARGB(255, 50, 50, 50)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < totalSteps - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final maxPages = (_attributes.isNotEmpty ? 2 : 1);
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentPage > 0 || _attributes.isNotEmpty)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: const Color.fromARGB(255, 50, 50, 50),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Back",
                    style: TextStyle(
                      color: Color.fromARGB(255, 50, 50, 50),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentPage > 0 || _attributes.isNotEmpty) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        if (_currentPage < maxPages) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _submitProduct();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 50, 50, 50),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentPage == maxPages ? "Post Product" : "Continue",
                  style: TextStyle(
                    color: canProceed ? Colors.white : Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    // Logic updated to reflect new step order
    if (_attributes.isNotEmpty && _currentPage == 0) {
       // Dynamic Attributes Step
       for (var attr in _attributes) {
        if (attr['is_required'] && (_dynamicFormValues[attr['field_label']] == null || _dynamicFormValues[attr['field_label']].toString().isEmpty)) {
          return false;
        }
      }
      return true;
    }
    return true; // Simplify for other steps
  }

  // STEP 1: DYNAMIC ATTRIBUTES
  Widget _buildDynamicAttributes() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 50, 50, 50),
                const Color.fromARGB(255, 70, 70, 70),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.selectedCategory['name']} Specs",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Fill in the specific details",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Dynamic Form Fields
        ..._attributes.asMap().entries.map((entry) {
          final attr = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field Label
                Row(
                  children: [
                    Text(
                      attr['field_label']?.toString() ?? 'Field',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (attr['is_required'] == true)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          "Required",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Field Input
                if (attr['field_type'] == 'dropdown')
                  _buildAttributeDropdown(attr)
                else
                  _buildAttributeInput(attr),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttributeDropdown(Map<String, dynamic> attr) {
    List<String> options = List<String>.from(attr['field_options'] ?? []);
    final fieldLabel = attr['field_label']?.toString() ?? 'Field';
    final currentValue = _dynamicFormValues[fieldLabel];
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: currentValue != null
              ? const Color.fromARGB(255, 50, 50, 50)
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          hint: Text(
            "Select $fieldLabel",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
            size: 20,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _dynamicFormValues[fieldLabel] = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAttributeInput(Map<String, dynamic> attr) {
    final fieldLabel = attr['field_label']?.toString() ?? 'Field';
    final currentValue = _dynamicFormValues[fieldLabel];
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: currentValue != null && currentValue.toString().isNotEmpty
              ? const Color.fromARGB(255, 50, 50, 50)
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        keyboardType: attr['field_type'] == 'number'
            ? TextInputType.number
            : TextInputType.text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C2C2C),
        ),
        decoration: InputDecoration(
          hintText: "Enter $fieldLabel",
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 8),
            child: Icon(
              attr['field_type'] == 'number' ? Icons.numbers : Icons.text_fields,
              color: Colors.grey[400],
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
          ),
        ),
        onChanged: (val) {
          setState(() {
            _dynamicFormValues[fieldLabel] = val;
          });
        },
      ),
    );
  }

  // STEP 2: BASIC INFO 
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Basic Information",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tell buyers about your product",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Images Section
          _buildImagesSection(),
          const SizedBox(height: 20),

          // Title Field
          _buildFormField(
            label: "Product Title",
            hint: "e.g., iPhone 13 Pro Max 256GB",
            icon: Icons.title,
            onChanged: (val) => _productData.name = val,
          ),
          const SizedBox(height: 16),

          // Price Field
          _buildFormField(
            label: "Price (ETB)",
            hint: "e.g., 45000",
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            onChanged: (val) => _productData.price = double.tryParse(val) ?? 0.0,
          ),
          const SizedBox(height: 16),

          // Description Field
          _buildFormField(
            label: "Description",
            hint: "Describe your product in detail...",
            icon: Icons.description_outlined,
            maxLines: 4,
            onChanged: (val) => _productData.description = val,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: TextField(
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2C),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: maxLines > 1 ? 12 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 8,
                  top: maxLines > 1 ? 12 : 0,
                ),
                child: Icon(
                  icon,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // FINAL STEP: REVIEW
  Widget _buildFinalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Review & Post",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Check everything looks good",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Images Section (if any)
          if (_mainImage != null || _additionalImages.isNotEmpty)
            _buildReviewSection(
              title: "Product Images",
              icon: Icons.image_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_mainImage != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Main Image",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_mainImage!.path),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  if (_mainImage != null && _additionalImages.isNotEmpty)
                    const SizedBox(height: 12),
                  if (_additionalImages.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Additional Images (${_additionalImages.length})",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _additionalImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(_additionalImages[index].path),
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (_mainImage != null || _additionalImages.isNotEmpty)
            const SizedBox(height: 12),

          // Category Section
          _buildReviewSection(
            title: "Category",
            icon: Icons.category_outlined,
            child: Text(
              widget.selectedCategory['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Basic Info Section
          if (_productData.name != null || _productData.price != null)
            _buildReviewSection(
              title: "Product Details",
              icon: Icons.info_outline,
              child: Column(
                children: [
                  if (_productData.name != null)
                    _buildReviewRow("Title", _productData.name!),
                  if (_productData.price != null)
                    _buildReviewRow("Price", "ETB ${_productData.price!.toStringAsFixed(2)}"),
                  if (_productData.description != null)
                    _buildReviewRow("Description", _productData.description!, maxLines: 2),
                ],
              ),
            ),
          if (_productData.name != null || _productData.price != null)
            const SizedBox(height: 12),

          // Specifications Section
          if (_dynamicFormValues.isNotEmpty)
            _buildReviewSection(
              title: "Specifications",
              icon: Icons.tune,
              child: Column(
                children: _dynamicFormValues.entries.map((entry) {
                  return _buildReviewRow(entry.key, entry.value.toString());
                }).toList(),
              ),
            ),
          if (_dynamicFormValues.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "No specifications added",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 50, 50, 50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: const Color.fromARGB(255, 50, 50, 50),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // IMAGE SELECTION SECTION
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Product Images",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                "1 main + 4 additional",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Main Image
        GestureDetector(
          onTap: _pickMainImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _mainImage != null 
                    ? Colors.orange.shade400 
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: _mainImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_mainImage!.path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Main",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _mainImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add Main Image",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to select from gallery",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Additional Images
        Text(
          "Additional Images (Optional)",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              final hasImage = index < _additionalImages.length;
              
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => hasImage 
                      ? _removeAdditionalImage(index)
                      : _pickAdditionalImage(),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasImage 
                            ? const Color.fromARGB(255, 50, 50, 50)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(_additionalImages[index].path),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Icon(
                            Icons.add_a_photo_outlined,
                            size: 28,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Image picker methods
  Future<void> _pickMainImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Compress the image before storing
        try {
          final compressedFile = await ImageHelper.compressImage(File(image.path));
          setState(() => _mainImage = compressedFile);
        } catch (e) {
          _showErrorSnackbar('Failed to compress image: ${e.toString()}');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalImages.length >= 4) {
      _showErrorSnackbar('Maximum 4 additional images allowed');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Compress the image before storing
        try {
          final compressedFile = await ImageHelper.compressImage(File(image.path));
          setState(() => _additionalImages.add(compressedFile));
        } catch (e) {
          _showErrorSnackbar('Failed to compress image: ${e.toString()}');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() => _additionalImages.removeAt(index));
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitProduct() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );

      // Prepare product data
      final productData = {
        'category_id': widget.selectedCategory['id'],
        'category_name': widget.selectedCategory['name'],
        'title': _productData.name,
        'description': _productData.description,
        'price': _productData.price,
        'attributes': _dynamicFormValues,
        'status': 'active',
      };

      // Prepare image paths (already compressed)
      final mainImagePath = _mainImage?.path;
      final additionalImagePaths = _additionalImages.map((img) => img.path).toList();

      // Send to backend
      final response = await ApiService.createProduct(
        productData,
        mainImagePath: mainImagePath,
        additionalImagePaths: additionalImagePaths,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response['success'] == true) {
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                  const SizedBox(width: 12),
                  const Text("Success!"),
                ],
              ),
              content: const Text("Your product has been posted successfully!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Go back to category selection
                    Navigator.pop(context); // Go back to home
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 28),
                  const SizedBox(width: 12),
                  const Text("Error"),
                ],
              ),
              content: Text(
                response['message'] ?? 'Failed to post product. Please try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 28),
                const SizedBox(width: 12),
                const Text("Error"),
              ],
            ),
            content: Text('An error occurred: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }
}

class ProductData {
  String? name;
  String? description;
  double? price;
  String? category;
}
