import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;

  ApiException(this.message);
}

String _requestAuthorization(Map<String, dynamic> token) {
  return '${token['token_type']} ${token['access_token']}';
}

Future<Map<String, dynamic>> apiRequest(Map<String, dynamic> token, String query, [Map<String, String>? variables]) async {
  Uri uri = Uri.parse(const String.fromEnvironment('API_URL'));
  const String clientId = const String.fromEnvironment('OAUTH_CLIENT_ID');
  Map<String, String> headers = {
    'Authorization': _requestAuthorization(token),
    'Content-Type': 'application/json',
    'X-Jwt-Aud': clientId
  };

  Map<String, dynamic> body = {
    'query': query,
    'variables': variables
  };
  body.removeWhere((key, value) => value == null);

  http.Response response = await http.post(
    uri,
    headers: headers,
    body: json.encode(body),
    encoding: Encoding.getByName('utf-8'),
  );

  if (response.statusCode != 200) {
    throw ApiException('Invalid response from the API.');
  }

  Map<String, dynamic> apiResponse = json.decode(response.body);

  if (apiResponse['errors'] is List<String>) {
    for (final error in apiResponse['errors']) {
      stderr.writeln(error);
    }
  }

  return apiResponse['data'] ?? <String, dynamic>{};
}
