import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>?> getMediaData({
    required String youtubeUrl, 
    required String serverUrl,
    required String apiPassword,
    bool isAudioOnly = false,
  }) async {
    
    final cleanServerUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    final url = Uri.parse('$cleanServerUrl/api/extract?url=${Uri.encodeComponent(youtubeUrl)}&audio_only=$isAudioOnly');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiPassword,
        },
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else if (response.statusCode == 401) {
        throw Exception('الباسورد غير صحيح ❌');
      } else {
        // 🔥 التعديل السحري هنا: قراءة الخطأ الحقيقي اللي البايثون بعته 🔥
        String errorDetail = 'خطأ غير معروف من السيرفر';
        try {
          final errorBody = jsonDecode(response.body);
          errorDetail = errorBody['detail'] ?? response.body;
        } catch (_) {
          errorDetail = 'كود الخطأ: ${response.statusCode}';
        }
        
        throw Exception('السبب: $errorDetail');
      }
    } catch (e) {
      throw Exception('${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }
}