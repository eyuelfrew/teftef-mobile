import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teftef/core/config.dart';

class ApiService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static const String baseUrl = AppConfig.baseUrl;
  static const String serverUrl = AppConfig.serverUrl;

  static Future<List<dynamic>> fetchCategoryTree() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/tree'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['categories'];
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      log('ERROR fetching categories: $e');
      // Return mock data as fallback when backend is not available
      return _getMockCategories();
    }
  }

  static Future<List<dynamic>> fetchAttributes(int categoryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attributes/$categoryId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['attributes'];
      } else {
        throw Exception('Failed to load attributes');
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetch dynamic attributes for a specific category
  static Future<Map<String, dynamic>> fetchCategoryAttributes(int categoryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attributes/category/$categoryId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data']['attributes'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load category attributes',
        };
      }
    } catch (e) {
      log('Error fetching category attributes: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Fetch product details by ID
  static Future<Map<String, dynamic>> fetchProductById(dynamic productId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$productId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data']['product'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch product details',
        };
      }
    } catch (e) {
      log('Error fetching product details: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Create a new product
  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData, {
    String? mainImagePath,
    List<String>? additionalImagePaths,
  }) async {
    try {
      // Get JWT token from secure storage
      final token = await _storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please sign in again.',
        };
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );

      // Add Authorization header with JWT token
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['name'] = productData['title']?.toString() ?? '';
      request.fields['description'] = productData['description']?.toString() ?? '';
      request.fields['price'] = productData['price']?.toString() ?? '0';
      request.fields['category'] = productData['category_id']?.toString() ?? '';
      request.fields['status'] = productData['status']?.toString() ?? 'draft';
      
      // Add metadata (dynamic attributes) as JSON string
      if (productData['attributes'] != null && (productData['attributes'] as Map).isNotEmpty) {
        request.fields['metadata'] = json.encode(productData['attributes']);
      }

      // Add main image
      if (mainImagePath != null && mainImagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('images', mainImagePath),
        );
      }

      // Add additional images
      if (additionalImagePaths != null && additionalImagePaths.isNotEmpty) {
        for (var imagePath in additionalImagePaths) {
          request.files.add(
            await http.MultipartFile.fromPath('images', imagePath),
          );
        }
      }

      log('Sending product creation request with token: ${token.substring(0, 20)}...');
      log('Images: main=${mainImagePath != null}, additional=${additionalImagePaths?.length ?? 0}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log('Product creation response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Product created successfully',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Authentication failed. Please sign in again.',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to create product',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to create product. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      log('Product creation error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update an existing product
  static Future<Map<String, dynamic>> updateProduct(
    dynamic productId,
    Map<String, dynamic> productData, {
    List<String>? newImages,
    List<String>? keepImages,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication required'};
      }

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/products/$productId'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Standard fields
      if (productData.containsKey('name')) request.fields['name'] = productData['name'].toString();
      if (productData.containsKey('description')) request.fields['description'] = productData['description'].toString();
      if (productData.containsKey('price')) request.fields['price'] = productData['price'].toString();
      if (productData.containsKey('category')) request.fields['category'] = productData['category'].toString();
      if (productData.containsKey('status')) request.fields['status'] = productData['status'].toString();

      // metadata (dynamic attributes)
      if (productData['metadata'] != null) {
        request.fields['metadata'] = json.encode(productData['metadata']);
      }

      // keepImages (existing images to retain)
      if (keepImages != null) {
        request.fields['keepImages'] = json.encode(keepImages);
      }

      // new images
      if (newImages != null && newImages.isNotEmpty) {
        for (var imagePath in newImages) {
          request.files.add(
            await http.MultipartFile.fromPath('images', imagePath),
          );
        }
      }

      log('Sending product update request for $productId...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Product updated successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      log('Product update error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Mock data for testing category images (matches backend structure)
  static List<dynamic> _getMockCategories() {
    return [
      {
        'id': 1,
        'name': 'Vehicles',
        'image': 'https://img.icons8.com/dusk/64/car--v1.png',
        'children': [
          {
            'id': 11,
            'name': 'Cars',
            'image': 'https://img.icons8.com/dusk/64/car--v1.png',
            'children': []
          },
          {
            'id': 12,
            'name': 'Motorcycles',
            'image': 'https://img.icons8.com/dusk/64/motorcycle.png',
            'children': []
          },
        ]
      },
      {
        'id': 2,
        'name': 'Electronics',
        'image': 'https://img.icons8.com/dusk/64/electronics.png',
        'children': [
          {
            'id': 21,
            'name': 'Mobile Phones',
            'image': 'https://img.icons8.com/dusk/64/smartphone.png',
            'children': []
          },
          {
            'id': 22,
            'name': 'Laptops',
            'image': 'https://img.icons8.com/dusk/64/laptop.png',
            'children': []
          },
        ]
      },
      {
        'id': 3,
        'name': 'Real Estate',
        'image': 'https://img.icons8.com/dusk/64/home.png',
        'children': [
          {
            'id': 31,
            'name': 'Houses',
            'image': 'https://img.icons8.com/dusk/64/house.png',
            'children': []
          },
          {
            'id': 32,
            'name': 'Apartments',
            'image': 'https://img.icons8.com/dusk/64/apartment.png',
            'children': []
          },
        ]
      },
      {
        'id': 4,
        'name': 'Fashion',
        'image': 'https://img.icons8.com/dusk/64/clothes.png',
        'children': []
      },
      {
        'id': 5,
        'name': 'Furniture',
        'image': 'https://img.icons8.com/dusk/64/furniture.png',
        'children': []
      },
      {
        'id': 6,
        'name': 'Jobs',
        'image': 'https://img.icons8.com/dusk/64/briefcase.png',
        'children': []
      },
    ];
  }

  /// Get user's products
  static Future<Map<String, dynamic>> getUserProducts({String? status}) async {
    try {
      // Get JWT token from secure storage
      final token = await _storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please sign in again.',
        };
      }

      // Build URL with optional status filter
      String url = '$baseUrl/users/me/products';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('Get user products response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data']['products'] ?? [],
          'message': 'Products loaded successfully',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Authentication failed. Please sign in again.',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to load products',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to load products. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      log('Get user products error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Fetch user-posted products with pagination
  /// Targets: GET /api/products/my-products
  static Future<Map<String, dynamic>> fetchMyProducts({int page = 1, int limit = 10}) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final url = '$baseUrl/products/my-products?page=$page&limit=$limit';
      log('Fetching my products: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data']['products'] ?? [],
          'pagination': data['pagination'],
          'results': data['results'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load your products',
        };
      }
    } catch (e) {
      log('Fetch my products error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Update product status
  static Future<Map<String, dynamic>> updateProductStatus(int productId, String status) async {
    try {
      // Get JWT token from secure storage
      final token = await _storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please sign in again.',
        };
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      log('Update product status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Product updated successfully',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Authentication failed. Please sign in again.',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to update product',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to update product. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      log('Update product status error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Fetch products with pagination
  /// 
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [limit]: Number of products per page (default: 10)
  /// 
  /// Returns: Map with pagination metadata and products list
  static Future<Map<String, dynamic>> fetchProducts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      log('Fetch products response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data']['products'] ?? [],
          'pagination': data['pagination'] ?? {},
          'message': 'Products loaded successfully',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to load products',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to load products. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      log('Fetch products error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete product
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      // Get JWT token from secure storage
      final token = await _storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please sign in again.',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('Delete product response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        Map<String, dynamic> data = {};
        if (response.body.isNotEmpty) {
          try {
            data = json.decode(response.body);
          } catch (e) {
            log('Error decoding delete response: $e');
          }
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Product deleted successfully',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Authentication failed. Please sign in again.',
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to delete product',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to delete product. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      log('Delete product error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Fetch available boost packages
  static Future<Map<String, dynamic>> fetchBoostPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/boost-packages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'packages': data['data']['packages'] ?? [],
        };
      } else {
        return {'success': false, 'message': 'Failed to load packages'};
      }
    } catch (e) {
      log('Fetch boost packages error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Fetch available payment agents
  static Future<Map<String, dynamic>> fetchPaymentAgents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/payment-agents'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'agents': data['data']['agents'] ?? [],
        };
      } else {
        return {'success': false, 'message': 'Failed to load payment agents'};
      }
    } catch (e) {
      log('Fetch payment agents error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Activate boost for a product with manual transaction verification via dynamic agents
  static Future<Map<String, dynamic>> activateBoost(dynamic productId, int packageId, int agentId, String transactionId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/boost'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'packageId': packageId,
          'agentId': agentId,
          'transactionId': transactionId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Boost request submitted successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit boost request',
        };
      }
    } catch (e) {
      log('Activate boost error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }
}

