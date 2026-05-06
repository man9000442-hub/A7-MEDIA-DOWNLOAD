import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../services/youtube_streaming_service.dart';

// 🔥 كلاس الوسيط "الذكي" - بياخد الرابط جاهز لمنع الحظر 🔥
class YtAudioSource extends StreamAudioSource {
  final AudioStreamInfo streamInfo;
  final YoutubeExplode ytClient;

  YtAudioSource(this.streamInfo, this.ytClient, {super.tag});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      // سحب البيانات من الرابط الجاهز مباشرة بدون طلب Manifest جديد
      final stream = ytClient.videos.streamsClient.get(streamInfo);
      
      return StreamAudioResponse(
        sourceLength: streamInfo.size.totalBytes,
        contentLength: streamInfo.size.totalBytes,
        offset: 0,
        stream: stream,
        contentType: 'audio/mpeg',
      );
    } catch (e) {
      print("Stream Error: $e");
      rethrow;
    }
  }
}

class OnlineMusicProvider with ChangeNotifier {
  final YoutubeExplode _ytClient = YoutubeExplode();
  final YouTubeStreamingService _api = YouTubeStreamingService();
  final AudioPlayer audioPlayer = AudioPlayer(); 

  List<Video> searchResults = [];
  bool isSearching = false;
  String? errorMessage;
  
  Video? currentPlayingVideo;
  bool isBuffering = false;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    isSearching = true;
    errorMessage = null;
    notifyListeners();

    try {
      searchResults = await _api.searchMusic(query);
    } catch (e) {
      errorMessage = "خطأ في الشبكة، جرب مرة أخرى";
    }
    isSearching = false;
    notifyListeners();
  }

  Future<void> playAudioOnline(Video video) async {
    try {
      currentPlayingVideo = video;
      isBuffering = true;
      errorMessage = null;
      notifyListeners();

      // 🔥 طلب الـ Manifest "مرة واحدة" فقط خارج حلقة الطلبات
      final manifest = await _ytClient.videos.streamsClient.getManifest(video.id);
      final streamInfo = manifest.audioOnly.withHighestBitrate();

      final mediaItem = MediaItem(
        id: video.id.value,
        album: "A7 Online",
        title: video.title,
        artist: video.author,
        artUri: Uri.parse(video.thumbnails.highResUrl),
      );

      // تمرير البيانات المستخرجة للـ Source
      final audioSource = YtAudioSource(
        streamInfo, 
        _ytClient, 
        tag: mediaItem,
      );

      await audioPlayer.stop();
      await audioPlayer.setAudioSource(audioSource);
      audioPlayer.play();
      
      isBuffering = false;
      notifyListeners();
    } catch (e) {
      isBuffering = false;
      // هندلة خطأ الحظر المؤقت بشكل احترافي
      if (e.toString().contains("Rate limiting")) {
        errorMessage = "يوتيوب قام بحظرك مؤقتاً، حاول تغيير الشبكة"; 
      } else {
        errorMessage = "تعذر التشغيل، جرب مقطعاً آخر";
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _api.dispose();
    _ytClient.close();
    super.dispose();
  }
}