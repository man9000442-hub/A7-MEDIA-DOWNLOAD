import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart'; 
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'queue_sheet.dart'; // 🔥 استدعاء طابور التشغيل
import 'options_sheet.dart'; 

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  double _dragX = 0.0; 
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _animationController.addListener(() {
      setState(() {
        _dragX = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.primaryDelta!;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, AudioProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_dragX > 80 || details.primaryVelocity! > 300) {
      _animateTo(screenWidth, () {
        provider.playPrevious();
        _resetAndSlideIn(fromLeft: true, screenWidth: screenWidth);
      });
    } else if (_dragX < -80 || details.primaryVelocity! < -300) {
      _animateTo(-screenWidth, () {
        provider.playNext();
        _resetAndSlideIn(fromLeft: false, screenWidth: screenWidth);
      });
    } else {
      _animateTo(0, () {}); 
    }
  }

  void _animateTo(double target, VoidCallback onComplete) {
    _animation = Tween<double>(begin: _dragX, end: target).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward(from: 0).then((_) => onComplete());
  }

  void _resetAndSlideIn({required bool fromLeft, required double screenWidth}) {
    setState(() {
      _dragX = fromLeft ? -screenWidth : screenWidth;
    });
    _animateTo(0, () {});
  }

  void _handleNext(AudioProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    _animateTo(-screenWidth, () {
      provider.playNext();
      _resetAndSlideIn(fromLeft: false, screenWidth: screenWidth);
    });
  }

  void _handlePrev(AudioProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    _animateTo(screenWidth, () {
      provider.playPrevious();
      _resetAndSlideIn(fromLeft: true, screenWidth: screenWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    final currentSong = provider.currentSong; 
    
    if (currentSong == null) return const SizedBox();
    
    final screenWidth = MediaQuery.of(context).size.width;

    double opacity = (1.0 - (_dragX.abs() / screenWidth)).clamp(0.0, 1.0);
    double scale = (1.0 - (_dragX.abs() / screenWidth) * 0.15).clamp(0.85, 1.0);

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      Container(
                        width: 50, height: 5,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                      ),
                      const SizedBox(height: 35),

                      // صورة الألبوم
                      GestureDetector(
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, provider),
                        child: Transform.translate(
                          offset: Offset(_dragX, 0),
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Hero(
                                tag: 'album_art_${currentSong.id}',
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.85,
                                  height: MediaQuery.of(context).size.width * 0.85,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: QueryArtworkWidget(
                                      id: currentSong.id,
                                      type: ArtworkType.AUDIO,
                                      artworkQuality: FilterQuality.high,
                                      size: 1000,
                                      nullArtworkWidget: Container(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        child: const Icon(Icons.music_note, size: 80, color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // اسم الأغنية والخيارات الكاملة والمفضلة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentSong.artist ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          
                          // زر المفضلة 
                          IconButton(
                            icon: Icon(
                              provider.isFavorite(currentSong.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                              color: provider.isFavorite(currentSong.id) ? AppColors.accent : Colors.white,
                              size: 28,
                            ), 
                            onPressed: () {
                              provider.toggleFavorite(currentSong.id);
                            },
                          ),

                          // زر الخيارات (كامل)
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 28), 
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                elevation: 0,
                                barrierColor: Colors.black.withValues(alpha: 0.5),
                                builder: (context) => OptionsSheet(song: currentSong, isFromPlayer: true),
                              );
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      // شريط التقدم
                      StreamBuilder<Duration>(
                        stream: provider.audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = provider.audioPlayer.duration ?? Duration.zero;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: Colors.white, inactiveTrackColor: Colors.white.withValues(alpha: 0.3), thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  min: 0.0, max: duration.inMilliseconds.toDouble(),
                                  value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                                  onChanged: (value) => provider.seek(Duration(milliseconds: value.toInt())),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position), style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                  Text(_formatDuration(duration), style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // أزرار التشغيل والتنقل
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 40), 
                            onPressed: () => _handlePrev(provider),
                          ),
                          StreamBuilder<bool>(
                            stream: provider.audioPlayer.playingStream,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data ?? false;
                              return Container(
                                width: 75, height: 75,
                                decoration: BoxDecoration(
                                  color: AppColors.accent, shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]
                                ),
                                child: IconButton(
                                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 40),
                                  onPressed: provider.togglePlayPause,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 40), 
                            onPressed: () => _handleNext(provider),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 🔥 الشريط السفلي المتكامل 🔥
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. العشوائي
                          StreamBuilder<bool>(
                            stream: provider.audioPlayer.shuffleModeEnabledStream,
                            builder: (context, snapshot) {
                              final isShuffle = snapshot.data ?? false;
                              return IconButton(icon: Icon(Icons.shuffle_rounded, color: isShuffle ? AppColors.accent : Colors.white70, size: 26), onPressed: provider.toggleShuffle);
                            },
                          ),
                          
                          // 2. 🔥 طابور التشغيل (اللي كان ناقص) 🔥
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 28),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => const QueueSheet(), // بيستدعي الشاشة العظمة اللي إنت بعتهالي
                              );
                            },
                          ),

                          // 3. الكلمات
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                            child: Row(children: [const Icon(Icons.lyrics_outlined, color: Colors.white, size: 18), const SizedBox(width: 8), Text('الكلمات', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold))]),
                          ),

                          // 4. التكرار
                          StreamBuilder<LoopMode>(
                            stream: provider.audioPlayer.loopModeStream,
                            builder: (context, snapshot) {
                              final loopMode = snapshot.data ?? LoopMode.off;
                              IconData icon = Icons.repeat_rounded;
                              Color color = Colors.white70;
                              
                              if (loopMode == LoopMode.one) {
                                icon = Icons.repeat_one_rounded;
                                color = AppColors.accent;
                              } else if (loopMode == LoopMode.all) {
                                color = AppColors.accent;
                              }
                              
                              return IconButton(
                                icon: Icon(icon, color: color, size: 26), 
                                onPressed: provider.toggleLoop,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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
}