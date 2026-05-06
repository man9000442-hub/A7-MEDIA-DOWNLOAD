import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeExtractorService {
  // 🔥 حطينا 3 سيرفرات بدل سيرفر واحد عشان لو واحد وقع التاني يشتغل تلقائي
  static const List<String> _apiUrls = [
    "https://pipedapi.kavin.rocks/streams/",
    "https://pipedapi.tokhmi.xyz/streams/",
    "https://pipedapi.syncpundit.io/streams/"
  ];

  static String? extractVideoId(String url) {
    try {
      RegExp regExp = RegExp(
        r'(?:https?:)?(?:\/\/)?(?:[0-9A-Z-]+\.)?(?:youtu\.be\/|youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=))([^"&?\n\s]{11})',
        caseSensitive: false,
      );
      Match? match = regExp.firstMatch(url);
      return match?.group(1);
    } catch (e) {
      print("❌ [A7-Extractor] Error parsing URL: $e");
      return null;
    }
  }

  static Future<String?> getAudioUrl(String youtubeUrl) async {
    String? videoId = extractVideoId(youtubeUrl);
    if (videoId == null) {
      print("❌ [A7-Extractor] Invalid Video ID");
      return null;
    }

    print("🔄 [A7-Extractor] جاري البحث عن روابط لـ Video ID: $videoId");

    // 🔥 اللوب ده هيجرب السيرفرات واحد ورا التاني لحد ما ينجح
    for (String apiUrl in _apiUrls) {
      try {
        print("🌐 [A7-Extractor] بنجرب سيرفر: $apiUrl");
        final response = await http.get(Uri.parse('$apiUrl$videoId')).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data.containsKey('audioStreams') && data['audioStreams'] is List) {
            List<dynamic> audioStreams = data['audioStreams'];
            
            if (audioStreams.isNotEmpty) {
              var bestAudioStream = audioStreams.firstWhere(
                (stream) => stream['mimeType'].toString().contains('audio/mp4'),
                orElse: () => audioStreams.first,
              );
              
              print("✅ [A7-Extractor] تم استخراج الرابط بنجاح!");
              return bestAudioStream['url']; // اللينك المباشر
            }
          }
        } else {
          print("⚠️ [A7-Extractor] السيرفر ده رفض الطلب: ${response.statusCode}");
        }
      } catch (e) {
        print("⚠️ [A7-Extractor] السيرفر ده مش بيرد أو واقع: $e");
      }
    }

    print("❌ [A7-Extractor] كل السيرفرات فشلت في استخراج الرابط.");
    return null;
  }
}