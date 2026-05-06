import 'package:flutter/material.dart';
import '../models/media_info.dart';
import '../services/youtube_service.dart';
import '../services/download_service.dart';

class MediaProvider with ChangeNotifier {
  final YouTubeService _ytService = YouTubeService();
  final DownloadService _downloadService = DownloadService(); 
  
  MediaInfo? currentMedia;
  bool isLoading = false;
  String? errorMessage;
  
  bool isDownloading = false;
  String? downloadStatusMessage;

  Future<void> searchVideo(String url) async {
    if (url.isEmpty || !url.contains('youtu')) {
      errorMessage = 'الرجاء إدخال رابط صحيح';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentMedia = await _ytService.getVideoMetadata(url);
    } catch (e) {
      errorMessage = 'تعذر جلب البيانات';
    }
    
    isLoading = false;
    notifyListeners();
  }

  // 🔥 شيلنا الـ Context من هنا عشان التحميل بيتم في النظام نفسه 🔥
  Future<void> startDownload(String videoUrl, String title, {bool isAudioOnly = false}) async {
    isDownloading = true;
    downloadStatusMessage = 'جاري التحضير...';
    notifyListeners();

    String fileName = "${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '')}.${isAudioOnly ? 'mp3' : 'mp4'}";

    await _downloadService.downloadFromYouTube(
      videoUrl: videoUrl,
      fileName: fileName,
      isAudioOnly: isAudioOnly,
      onStatus: (status) {
        downloadStatusMessage = status;
        notifyListeners(); 
      },
      onSuccess: () {
        // 🔥 رسالة نجاح الإرسال لمدير تحميلات أندرويد 🔥
        downloadStatusMessage = '✅ بدأ التحميل! (اسحب شريط الإشعارات من الأعلى)';
        notifyListeners();
        _resetDownloadState();
      },
      onError: (error) {
        downloadStatusMessage = '❌ $error';
        notifyListeners();
        _resetDownloadState();
      },
    );
  }

  void _resetDownloadState() {
    Future.delayed(const Duration(seconds: 4), () {
      isDownloading = false;
      notifyListeners();
    });
  }
}