import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadService {
  // القناة اللي بتكلمنا مع كود الكوتلن اللي لسه كاتبينه
  static const platform = MethodChannel('com.a7.media/download');

  Future<void> downloadFromYouTube({
    required String videoUrl,
    required String fileName,
    required bool isAudioOnly,
    required Function(String status) onStatus, 
    required Function(String error) onError,
    required Function() onSuccess,
  }) async {
    
    var yt = YoutubeExplode();
    try {
      onStatus('جاري استخراج الرابط المباشر...');
      
      var manifest = await yt.videos.streamsClient.getManifest(VideoId(videoUrl));
      var streamInfo = isAudioOnly 
          ? manifest.audioOnly.withHighestBitrate() 
          : manifest.muxed.withHighestBitrate();

      String directUrl = streamInfo.url.toString();

      onStatus('جاري إرسال الرابط لمحرك أندرويد...');
      
      // 🔥 الضربة القاضية: رمي الرابط لمدير تحميلات الأندرويد 🔥
      await platform.invokeMethod('downloadFile', {
        'url': directUrl,
        'title': fileName,
      });

      onSuccess(); 
    } catch (e) {
      onError('فشل التحميل: تأكد من الإنترنت');
    } finally {
      yt.close();
    }
  }
}