// ignore_for_file: avoid_print
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:5288/api',
    // Fake the auth token if needed, but CreateSubmission doesn't strictly check signature in test env?
    // Actually, it requires a JWT bearer token. Let's just catch what the server says.
  ));
  
  try {
    print('Sending POST /submissions...');
    final response = await dio.post('/submissions', data: {
      "templateId": "11111111-1111-1111-1111-111111111111",
      "storeId": "22222222-2222-2222-2222-222222222222",
      "clientScore": 100.0,
      "status": "completed",
      "answers": [
        {
          "criteriaId": "33333333-3333-3333-3333-333333333333",
          "value": "conform",
          "isRepeatedError": false
        }
      ]
    });
    print('Success: ${response.statusCode}');
  } on DioException catch (e) {
    if (e.response != null) {
      print('HTTP ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
    } else {
      print('Network Error: ${e.message}');
    }
  }
}
