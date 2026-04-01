import 'dart:convert';
import 'dart:io';

void main() async {
  final request = await HttpClient().post('127.0.0.1', 5000, '/api/auth/login');
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode({
    'email': 'admin@test.com',
    'password': 'Admin123!',
  }));
  
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('Status: ${response.statusCode}');
  print('Body: $responseBody');
}
