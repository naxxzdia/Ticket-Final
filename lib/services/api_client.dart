import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

// Determine a sensible default base URL depending on platform:
// - Android emulator cannot reach host machine via 'localhost', must use 10.0.2.2
// - Other platforms (iOS simulator, web, desktop) can usually use localhost
String resolveDefaultBaseUrl() {
  const fallbackPort = '3000';
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  return 'http://$host:$fallbackPort';
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? resolveDefaultBaseUrl();

  final http.Client _client;
  final String baseUrl;

  Future<List<dynamic>> getJsonList(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final resp = await _client.get(uri, headers: {
      'Accept': 'application/json',
    });
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'] as List<dynamic>;
      throw const FormatException('Unexpected JSON structure');
    } else {
      throw HttpException('GET $path failed (${resp.statusCode})');
    }
  }
  Future<Map<String, dynamic>> getJsonObject(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final resp = await _client.get(uri, headers: {
      'Accept': 'application/json',
    });
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map && data['data'] is Map<String, dynamic>) return data['data'] as Map<String, dynamic>;
      throw const FormatException('Unexpected JSON object structure');
    } else {
      throw HttpException('GET $path failed (${resp.statusCode})');
    }
  }

  void dispose() {
    _client.close();
  }
}

class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
