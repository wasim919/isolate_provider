import 'package:http/http.dart' as http;

// Http Client for making REST API calls
class HttpClient {
  static Future<String> fetch(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
      );
      return response.body;
    } catch (e) {
      rethrow;
    }
  }
}
