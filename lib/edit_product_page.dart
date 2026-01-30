// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teftef/core/config.dart';
import 'package:teftef/services/api_service.dart';

class EditProductPage extends StatefulWidget {
  final dynamic product; // Can be a Map or an ID

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _fullProduct;
  List<dynamic> _attributes = [];
  Map<String, dynamic> _dynamicFormValues = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<String> _existingImages = []; // URLs
  final List<String> _newImages = []; // Local paths
  List<String> _keepImages = []; // URLs to retain

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.product is Map) {
        _fullProduct = Map<String, dynamic>.from(widget.product);
      } else {
        final res = await ApiService.fetchProductById(widget.product);
        if (res['success']) {
          _fullProduct = res['data'];
        }
      }

      if (_fullProduct != null) {
        // Pre-fill standard fields
        _nameController.text = _fullProduct!['name'] ?? '';
        _priceController.text = _fullProduct!['price']?.toString() ?? '';
        _descriptionController.text = _fullProduct!['description'] ?? '';
        
        // Setup images
        _existingImages = List<String>.from(_fullProduct!['images'] ?? []);
        _keepImages = List<String>.from(_existingImages);

        // Pre-fill metadata
        if (_fullProduct!['metadata'] != null) {
          _dynamicFormValues = Map<String, dynamic>.from(_fullProduct!['metadata']);
        }

        // Fetch attributes for category
        final categoryId = _fullProduct!['category_id'] ?? _fullProduct!['category'];
        if (categoryId != null) {
          final attrRes = await ApiService.fetchCategoryAttributes(int.parse(categoryId.toString()));
          if (attrRes['success']) {
            _attributes = attrRes['data'];
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _newImages.add(image.path);
      });
    }
  }

  void _removeExistingImage(String url) {
    setState(() {
      _keepImages.remove(url);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedData = {
      'name': _nameController.text,
      'price': _priceController.text,
      'description': _descriptionController.text,
      'metadata': _dynamicFormValues,
    };

    try {
      final res = await ApiService.updateProduct(
        _fullProduct!['id'],
        updatedData,
        newImages: _newImages,
        keepImages: _keepImages,
      );

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text('SAVE', style: TextStyle(color: Color(0xFF1B4D3E), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Basic Information', Icons.info_outline),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Product Name', Icons.shopping_bag_outlined),
            const SizedBox(height: 12),
            _buildTextField(_priceController, 'Price (ETB)', Icons.payments_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(_descriptionController, 'Description', Icons.description_outlined, maxLines: 3),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Standard Specs', Icons.tune),
            const SizedBox(height: 16),
            ..._attributes.map((attr) => _buildDynamicField(attr)),

            const SizedBox(height: 32),
            _buildSectionHeader('Images', Icons.photo_library_outlined),
            const SizedBox(height: 16),
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B4D3E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
      ),
    );
  }

  Widget _buildDynamicField(Map<String, dynamic> attr) {
    final label = attr['field_label'] ?? 'Attribute';
    final type = attr['field_type'] ?? 'text';
    final options = List<String>.from(attr['field_options'] ?? []);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 6),
          if (type == 'dropdown')
            _buildDropdown(label, options)
          else
            _buildDynamicInput(label, type == 'number'),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _dynamicFormValues[label],
          hint: Text('Select $label'),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (val) => setState(() => _dynamicFormValues[label] = val),
        ),
      ),
    );
  }

  Widget _buildDynamicInput(String label, bool isNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        initialValue: _dynamicFormValues[label]?.toString(),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: 'Enter $label',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => _dynamicFormValues[label] = val,
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing and new images grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _keepImages.length + _newImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _keepImages.length + _newImages.length) {
              return _buildAddButton();
            }

            if (index < _keepImages.length) {
              final url = _keepImages[index];
              return _buildImageCard(AppConfig.getImageUrl(url), true, () => _removeExistingImage(url));
            }

            final localPath = _newImages[index - _keepImages.length];
            return _buildImageCard(localPath, false, () => _removeNewImage(index - _keepImages.length));
          },
        ),
        if (_keepImages.length < _existingImages.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_existingImages.length - _keepImages.length} existing images will be removed.',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImageCard(String path, bool isNetwork, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: isNetwork 
                ? Image.network(path, fit: BoxFit.cover) 
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
