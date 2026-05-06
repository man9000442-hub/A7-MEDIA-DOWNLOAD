import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeStreamingService {
  final YoutubeExplode _yt = YoutubeExplode();

  // 1. محرك بحث قوي يرجع قائمة بالفيديوهات
  Future<List<Video>> searchMusic(String query) async {
    try {
      // بنجيب أول 20 نتيجة للبحث
      final searchList = await _yt.search(query);
      return searchList.toList();
    } catch (e) {
      throw Exception('فشل البحث: تأكد من الاتصال بالإنترنت');
    }
  }

  // 2. دالة لاستخراج الرابط السري المباشر للصوت
  Future<String> getAudioStreamUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      // بنجيب أعلى جودة صوت متاحة
      var audioStream = manifest.audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } catch (e) {
      throw Exception('لا يمكن تشغيل هذا المقطع حالياً');
    }
  }
  // جوه ملف youtube_streaming_service.dart
  Future<StreamManifest> getManifest(String videoId) async {
    return await _yt.videos.streamsClient.getManifest(videoId);
  }

  void dispose() {
    _yt.close();
  }
}