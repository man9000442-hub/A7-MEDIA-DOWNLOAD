import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_manager/photo_manager.dart'; 

class AudioProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer audioPlayer = AudioPlayer();

  // --- 1. متغيرات الصوتيات ---
  List<SongModel> songs = [];
  bool isLoading = true;
  // 🔥 الترتيب الافتراضي أصبح "الأحدث إضافة" 🔥
  String songSortOrder = 'date_added'; 

  // --- 2. متغيرات الفيديوهات ---
  List<SongModel> videos = [];
  bool isVideosLoading = true;
  String videoSortOrder = 'date'; 

  // --- 3. ذاكرة الطابور الحالي (Queue) ---
  List<SongModel> _currentQueue = [];
  List<SongModel> get currentQueue => _currentQueue.isEmpty ? songs : _currentQueue;

  SongModel? get currentSong {
    if (audioPlayer.currentIndex == null) return null;
    if (currentQueue.isNotEmpty && audioPlayer.currentIndex! < currentQueue.length) {
      return currentQueue[audioPlayer.currentIndex!];
    }
    return null;
  }

  int? get currentIndex => audioPlayer.currentIndex;

  // --- 4. متغيرات المفضلة وقوائم التشغيل ---
  List<int> _favoriteIds = [];
  Map<String, List<int>> _customPlaylists = {};
  
  List<int> get favoriteIds => _favoriteIds;
  Map<String, List<int>> get customPlaylists => _customPlaylists;

  // --- 5. التهيئة الأولية ---
  AudioProvider() {
    initPlayer();
  }

  Future<void> initPlayer() async {
    try {
      bool hasPermission = await _audioQuery.permissionsStatus();
      if (!hasPermission) hasPermission = await _audioQuery.permissionsRequest();

      if (hasPermission) {
        songs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        songs.removeWhere((song) => song.data.isEmpty);
        
        _applySongSort(); // تطبيق الترتيب على الأغاني
        _currentQueue = songs;

        await loadFavorites();
        await loadCustomPlaylists();
      }
    } catch (e) {
      print("Error initialization: $e");
    }

    isLoading = false;
    notifyListeners();
    loadVideos(); 

    audioPlayer.currentIndexStream.listen((_) => notifyListeners());
    audioPlayer.playingStream.listen((_) => notifyListeners());
    audioPlayer.shuffleModeEnabledStream.listen((_) => notifyListeners());
    audioPlayer.loopModeStream.listen((_) => notifyListeners());
  }

  // 🔥 دوال ترتيب الأغاني الجديدة 🔥
  void setSongSortOrder(String order) {
    if (songSortOrder != order) {
      songSortOrder = order;
      _applySongSort();
      notifyListeners();
    }
  }

  void _applySongSort() {
    try {
      if (songSortOrder == 'name') {
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      } else if (songSortOrder == 'artist') {
        songs.sort((a, b) => (a.artist ?? '').toLowerCase().compareTo((b.artist ?? '').toLowerCase()));
      } else if (songSortOrder == 'size') {
        songs.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
      } else if (songSortOrder == 'duration') {
        songs.sort((a, b) => (b.duration ?? 0).compareTo(a.duration ?? 0));
      } else if (songSortOrder == 'date_added') {
        // 🔥 ترتيب بالأحدث إضافة (التنازلي) 🔥
        songs.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
      }
    } catch(e) {}
  }

  // --- 6. جلب وترتيب الفيديوهات ---
  Future<void> loadVideos() async {
    isVideosLoading = true;
    notifyListeners();

    try {
      videos.clear();
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      
      if (ps.isAuth || ps.hasAccess) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.video);
        if (albums.isNotEmpty) {
          final recentAlbum = albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
          final assetCount = await recentAlbum.assetCountAsync; 
          List<AssetEntity> media = await recentAlbum.getAssetListRange(start: 0, end: assetCount);
          
          List<SongModel> tempVideos = [];
          for (int i = 0; i < media.length; i += 50) {
            final chunk = media.sublist(i, i + 50 > media.length ? media.length : i + 50);
            final futures = chunk.map((asset) async {
              try {
                final file = await asset.file; 
                if (file != null) {
                  return SongModel({
                    '_id': asset.id.hashCode,
                    'title': asset.title ?? file.path.split('/').last,
                    '_data': file.path,
                    'artist': 'الفيديوهات',
                    '_size': file.lengthSync(),
                    'date_added': asset.createDateTime.millisecondsSinceEpoch ~/ 1000,
                    'duration': asset.videoDuration.inMilliseconds,
                  });
                }
              } catch(e) {}
              return null;
            });
            final results = await Future.wait(futures);
            for (var r in results) { if (r != null) tempVideos.add(r); }
          }
          videos = tempVideos;
        }
      }
      _applyVideoSort();
    } catch (e) {}

    isVideosLoading = false;
    notifyListeners();
  }

  void setVideoSortOrder(String order) {
    if (videoSortOrder != order) {
      videoSortOrder = order;
      _applyVideoSort();
      notifyListeners();
    }
  }

  void _applyVideoSort() {
    try {
      if (videoSortOrder == 'name') {
        videos.sort((a, b) => (a.title).toLowerCase().compareTo((b.title).toLowerCase()));
      } else if (videoSortOrder == 'size') {
        videos.sort((a, b) {
          int sizeA = int.tryParse(a.getMap['_size']?.toString() ?? '0') ?? 0;
          int sizeB = int.tryParse(b.getMap['_size']?.toString() ?? '0') ?? 0;
          return sizeB.compareTo(sizeA); 
        });
      } else { 
        videos.sort((a, b) {
          int dateA = int.tryParse(a.getMap['date_added']?.toString() ?? '0') ?? 0;
          int dateB = int.tryParse(b.getMap['date_added']?.toString() ?? '0') ?? 0;
          return dateB.compareTo(dateA); 
        });
      }
    } catch(e) {}
  }

  // --- 7. التحكم في التشغيل ---
  Future<void> playSong(SongModel song, {required List<SongModel> queue}) async {
    _currentQueue = queue; 
    int indexInQueue = queue.indexWhere((s) => s.id == song.id);
    if (indexInQueue == -1) return;

    try {
      final audioSource = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: queue.map((s) => AudioSource.uri(
          Uri.file(s.data), 
          tag: MediaItem(id: s.id.toString(), title: s.title, artist: s.artist ?? 'غير معروف', album: s.album ?? 'غير معروف'),
        )).toList(),
      );

      await audioPlayer.setAudioSource(audioSource, initialIndex: indexInQueue);
      
      if (audioPlayer.shuffleModeEnabled) {
        await audioPlayer.shuffle(); 
      }
      
      audioPlayer.play();
      notifyListeners();
    } catch (e) {}
  }

  void togglePlayPause() => audioPlayer.playing ? audioPlayer.pause() : audioPlayer.play();
  void playNext() {
    if (audioPlayer.currentIndex == null) return;
    if (audioPlayer.loopMode == LoopMode.one) {
      int? nextIndex;
      if (audioPlayer.shuffleModeEnabled) {
        final indices = audioPlayer.effectiveIndices ?? [];
        if (indices.isNotEmpty) {
          final pos = indices.indexOf(audioPlayer.currentIndex!);
          nextIndex = (pos + 1 < indices.length) ? indices[pos + 1] : indices.first;
        }
      } else {
        nextIndex = (audioPlayer.currentIndex! < currentQueue.length - 1) ? audioPlayer.currentIndex! + 1 : 0;
      }
      if (nextIndex != null) audioPlayer.seek(Duration.zero, index: nextIndex);
    } else {
      if (audioPlayer.hasNext) audioPlayer.seekToNext();
    }
  }

  void playPrevious() {
    if (audioPlayer.currentIndex == null) return;
    if (audioPlayer.loopMode == LoopMode.one) {
      int? prevIndex;
      if (audioPlayer.shuffleModeEnabled) {
        final indices = audioPlayer.effectiveIndices ?? [];
        if (indices.isNotEmpty) {
          final pos = indices.indexOf(audioPlayer.currentIndex!);
          prevIndex = (pos > 0) ? indices[pos - 1] : indices.last;
        }
      } else {
        prevIndex = (audioPlayer.currentIndex! > 0) ? audioPlayer.currentIndex! - 1 : currentQueue.length - 1;
      }
      if (prevIndex != null) audioPlayer.seek(Duration.zero, index: prevIndex);
    } else {
      if (audioPlayer.hasPrevious) audioPlayer.seekToPrevious();
    }
  }

  void seek(Duration position) => audioPlayer.seek(position);
  void toggleShuffle() async {
    final newState = !audioPlayer.shuffleModeEnabled;
    await audioPlayer.setShuffleModeEnabled(newState);
    if (newState) {
      await audioPlayer.shuffle(); 
    }
    notifyListeners();
  }
  void toggleLoop() {
    final currentMode = audioPlayer.loopMode;
    if (currentMode == LoopMode.off) audioPlayer.setLoopMode(LoopMode.all);
    else if (currentMode == LoopMode.all) audioPlayer.setLoopMode(LoopMode.one);
    else audioPlayer.setLoopMode(LoopMode.off);
    notifyListeners();
  }
  void setSpeed(double speed) { audioPlayer.setSpeed(speed); notifyListeners(); }

  // --- 8. المفضلة وقوائم التشغيل ---
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favString = prefs.getString('favorites');
    if (favString != null && favString.isNotEmpty) {
      _favoriteIds = favString.split(',').map(int.parse).toList();
      notifyListeners();
    }
  }
  Future<void> toggleFavorite(int songId) async {
    _favoriteIds.contains(songId) ? _favoriteIds.remove(songId) : _favoriteIds.add(songId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', _favoriteIds.join(','));
    notifyListeners();
  }
  bool isFavorite(int songId) => _favoriteIds.contains(songId);

  Future<void> loadCustomPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsString = prefs.getString('custom_playlists');
    if (playlistsString != null && playlistsString.isNotEmpty) {
      try {
        final decoded = json.decode(playlistsString) as Map<String, dynamic>;
        _customPlaylists = {};
        decoded.forEach((key, value) { _customPlaylists[key] = List<int>.from(value as List); });
        notifyListeners();
      } catch (e) {}
    }
  }
  Future<void> createPlaylist(String name) async {
    if (!_customPlaylists.containsKey(name) && name.trim().isNotEmpty) {
      _customPlaylists[name] = [];
      await _saveCustomPlaylists();
    }
  }
  Future<void> renamePlaylist(String oldName, String newName) async {
    final trimmedNewName = newName.trim();
    if (_customPlaylists.containsKey(oldName) && trimmedNewName.isNotEmpty && !_customPlaylists.containsKey(trimmedNewName)) {
      final songs = _customPlaylists[oldName]!;
      _customPlaylists.remove(oldName);
      _customPlaylists[trimmedNewName] = songs;
      await _saveCustomPlaylists();
    }
  }
  Future<void> updatePlaylistSongs(String playlistName, List<int> songIds) async {
    if (_customPlaylists.containsKey(playlistName)) {
      _customPlaylists[playlistName] = songIds;
      await _saveCustomPlaylists();
    }
  }
  Future<void> addSongToPlaylist(String playlistName, int songId) async {
    if (_customPlaylists.containsKey(playlistName) && !_customPlaylists[playlistName]!.contains(songId)) {
      _customPlaylists[playlistName]!.add(songId);
      await _saveCustomPlaylists();
    }
  }
  Future<void> _saveCustomPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_playlists', json.encode(_customPlaylists));
    notifyListeners();
  }

  // --- 9. المشاركة والحذف ---
  void shareSong(SongModel song) {
    if (song.data.isNotEmpty) Share.shareXFiles([XFile(song.data)], text: 'اسمع الأغنية دي عبر تطبيق A7!');
    else Share.share('اسمع الأغنية دي: ${song.title}');
  }
  void shareMultipleSongs(List<SongModel> songsToShare) {
    final files = songsToShare.where((s) => s.data.isNotEmpty).map((s) => XFile(s.data)).toList();
    if (files.isNotEmpty) Share.shareXFiles(files, text: 'شوف الحاجات دي عبر تطبيق A7!');
  }
  Future<void> deleteSongs(List<SongModel> songsToDelete) async {
    for (var song in songsToDelete) {
      try {
        final file = File(song.data);
        if (await file.exists()) await file.delete();
      } catch (e) {}
      songs.removeWhere((s) => s.id == song.id);
      videos.removeWhere((v) => v.id == song.id);
      _currentQueue.removeWhere((s) => s.id == song.id);
      _favoriteIds.remove(song.id);
      _customPlaylists.forEach((key, value) => value.remove(song.id));
    }
    await _saveCustomPlaylists();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', _favoriteIds.join(','));
    notifyListeners();
  }
  @override void dispose() { audioPlayer.dispose(); super.dispose(); }
}