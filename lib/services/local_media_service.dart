import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalMediaService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // 1. طلب الصلاحيات اللازمة لقراءة الملفات
  Future<bool> requestPermissions() async {
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      permissionStatus = await _audioQuery.permissionsRequest();
    }
    
    // تأكيد إضافي للأندرويد الحديث
    var status = await Permission.audio.request();
    var storageStatus = await Permission.storage.request();
    
    return permissionStatus || status.isGranted || storageStatus.isGranted;
  }

  // 2. جلب جميع الأغاني والمقاطع الصوتية من الجهاز
  Future<List<SongModel>> fetchAllSongs() async {
    bool hasPermission = await requestPermissions();
    
    if (hasPermission) {
      return await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } else {
      print('تم رفض صلاحيات قراءة الملفات');
      return [];
    }
  }

  // 3. جلب الألبومات (لو عايزين نقسمهم مستقبلاً)
  Future<List<AlbumModel>> fetchAlbums() async {
    return await _audioQuery.queryAlbums();
  }
}