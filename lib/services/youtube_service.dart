import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_info.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<MediaInfo?> getVideoMetadata(String url) async {
    try {
      var video = await _yt.videos.get(url);
      return MediaInfo(
        id: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration ?? Duration.zero,
        thumbnailUrl: video.thumbnails.highResUrl,
      );
    } catch (e) {
      print('حدث خطأ أثناء جلب بيانات الفيديو: $e');
      return null;
    }
  }

  Future<StreamManifest?> getDownloadStreams(String videoId) async {
    try {
      return await _yt.videos.streamsClient.getManifest(videoId);
    } catch (e) {
      print('حدث خطأ أثناء جلب روابط التحميل: $e');
      return null;
    }
  }

  // الدالة الرسمية لجلب البيانات المشفرة مباشرة من يوتيوب
  Stream<List<int>> getMediaStream(StreamInfo streamInfo) {
    return _yt.videos.streamsClient.get(streamInfo);
  }

  void dispose() {
    _yt.close();
  }
}