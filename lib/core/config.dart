
class AppConfig {
  // Base URL for the backend server
  // Use http://10.0.2.2:5000 for Android Emulator
  // Use http://localhost:5000 for iOS Simulator / Web / Windows
  static const String serverUrl = "http://localhost:5000";
  
  // API Base URL
  static const String baseUrl = "$serverUrl/api";

  // Get formatted image URL
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "$serverUrl$path";
  }
}
