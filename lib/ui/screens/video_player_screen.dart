import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final bool isNetwork;

  const VideoPlayerScreen({super.key, required this.videoPath, this.isNetwork = false});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isFullScreen = false;
  
  // متغيرات وضع تيك توك والتقليب
  bool _isTikTokMode = true; // مفعل كافتراضي
  List<SongModel> _videos = [];
  int _currentIndex = 0;
  bool _isTransitioning = false; // عشان نحط علامة تحميل وقت تقليب الفيديو
  
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    // 1. نجيب قائمة الفيديوهات من العقل عشان نعرف نقلب
    _videos = Provider.of<AudioProvider>(context, listen: false).videos;
    
    // 2. نعرف إحنا واقفين على أنهي فيديو حالياً
    _currentIndex = _videos.indexWhere((v) => v.data == widget.videoPath);
    if (_currentIndex == -1) _currentIndex = 0;

    // 3. نشغل الفيديو
    _initPlayer(widget.videoPath, widget.isNetwork);
  }

  // دالة تشغيل الفيديو (مسؤولة عن التقليب السلس)
  Future<void> _initPlayer(String path, [bool isNetwork = false]) async {
    setState(() => _isTransitioning = true);

    // لو في فيديو شغال نمسحه من الذاكرة الأول
    if (_controller != null) {
      await _controller!.pause();
      _controller!.dispose();
    }

    if (isNetwork) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.file(File(path));
    }

    await _controller!.initialize();
    _controller!.setPlaybackSpeed(_currentSpeed); // الحفاظ على السرعة الحالية
    
    _controller!.addListener(() {
      if (mounted) setState(() {});
    });

    _controller!.play();
    if (mounted) setState(() => _isTransitioning = false);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _controller?.dispose();
    super.dispose();
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
  }

  // 🔥 دالة السحب (وضع تيك توك) 🔥
  void _onVerticalDragEnd(DragEndDetails details) {
    // نوقف السحب لو الشاشة كاملة، أو الوضع مقفول، أو ده فيديو من النت
    if (_isFullScreen || !_isTikTokMode || _isTransitioning || widget.isNetwork || _videos.isEmpty) return;

    if (details.primaryVelocity! < -300) {
      // سحب لفوق -> الفيديو التالي
      if (_currentIndex < _videos.length - 1) {
        _currentIndex++;
        _initPlayer(_videos[_currentIndex].data);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أنت في الفيديو الأخير 🎬', style: GoogleFonts.tajawal()), backgroundColor: AppColors.accent, duration: const Duration(seconds: 1)));
      }
    } else if (details.primaryVelocity! > 300) {
      // سحب لتحت -> الفيديو السابق
      if (_currentIndex > 0) {
        _currentIndex--;
        _initPlayer(_videos[_currentIndex].data);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أنت في الفيديو الأول 🎬', style: GoogleFonts.tajawal()), backgroundColor: AppColors.accent, duration: const Duration(seconds: 1)));
      }
    }
  }

  void _showSpeedDialog() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF11221A).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('سرعة التشغيل', style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                  children: speeds.map((s) => ActionChip(
                    label: Text('${s}x', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.black)),
                    backgroundColor: _currentSpeed == s ? AppColors.accent : Colors.white70,
                    onPressed: () {
                      setState(() => _currentSpeed = s);
                      _controller?.setPlaybackSpeed(s);
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          // دمجنا التمرير (تيك توك) والضغط (إظهار/إخفاء الأدوات)
          onVerticalDragEnd: _onVerticalDragEnd,
          onTap: _toggleControls,
          child: Stack(
            children: [
              // 1. الفيديو في الخلفية
              Center(
                child: _isTransitioning || _controller == null || !_controller!.value.isInitialized
                    ? const CircularProgressIndicator(color: AppColors.accent)
                    : AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
              ),

              // 2. الشريط العلوي (الرجوع وزرار تيك توك)
              if (_showControls && !_isFullScreen)
                Positioned(
                  top: 20, left: 20, right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                      
                      // زرار تفعيل/إلغاء وضع تيك توك
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: _isTikTokMode ? AppColors.accent.withValues(alpha: 0.2) : Colors.black45, shape: BoxShape.circle),
                          child: Icon(Icons.swap_vert_rounded, color: _isTikTokMode ? AppColors.accent : Colors.white, size: 26),
                        ),
                        onPressed: () {
                          setState(() => _isTikTokMode = !_isTikTokMode);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_isTikTokMode ? 'تم تفعيل التمرير العمودي (TikTok) 📱' : 'تم إيقاف التمرير العمودي 🔒', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.accent, duration: const Duration(seconds: 1)
                          ));
                        },
                      ),
                    ],
                  ),
                ),

              // 3. الفقاعة السفلية الشاملة
              if (_showControls && _controller != null && _controller!.value.isInitialized)
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF11221A).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- الصف الأول: شريط التقدم ---
                            SliderTheme(
                              data: SliderThemeData(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), activeTrackColor: AppColors.accent, inactiveTrackColor: Colors.white.withValues(alpha: 0.3), thumbColor: AppColors.accent),
                              child: Slider(
                                min: 0.0, max: _controller!.value.duration.inMilliseconds.toDouble(),
                                value: _controller!.value.position.inMilliseconds.toDouble().clamp(0.0, _controller!.value.duration.inMilliseconds.toDouble()),
                                onChanged: (value) => _controller!.seekTo(Duration(milliseconds: value.toInt())),
                              ),
                            ),
                            
                            // --- الصف الثاني: الوقت وأزرار الإيقاف والتشغيل ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(_controller!.value.position), style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28), onPressed: () => _controller!.seekTo(_controller!.value.position - const Duration(seconds: 10))),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.2)), 
                                      child: IconButton(icon: Icon(_controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.accent, size: 36), onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()))
                                    ),
                                    IconButton(icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28), onPressed: () => _controller!.seekTo(_controller!.value.position + const Duration(seconds: 10))),
                                  ],
                                ),
                                Text(_formatDuration(_controller!.value.duration), style: GoogleFonts.tajawal(color: Colors.white70, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            
                            const SizedBox(height: 5),
                            Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                            
                            // --- الصف الثالث: السرعة والشاشة الكاملة ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.speed_rounded, color: AppColors.accent, size: 22),
                                  label: Text('السرعة ${_currentSpeed}x', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w600)),
                                  onPressed: _showSpeedDialog,
                                ),
                                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.2)), // خط فاصل شيك
                                TextButton.icon(
                                  icon: Icon(_isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: AppColors.accent, size: 24),
                                  label: Text('ملء الشاشة', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w600)),
                                  onPressed: _toggleFullScreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}