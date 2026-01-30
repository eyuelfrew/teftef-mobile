import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:teftef/core/config.dart';

class ApiClient {
  // Centralized server URL
  static const String baseUrl = AppConfig.serverUrl;

  // GET request
  Future<http.Response> get(String endpoint) async {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  // POST request
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  // PUT request
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}