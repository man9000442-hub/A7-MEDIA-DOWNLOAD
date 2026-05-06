import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    
    // 1. الطابور الأساسي (اللي عارف هو فنان ولا قائمة ولا مفضلة)
    final baseQueue = provider.currentQueue; 

    // 2. 🔥 الخوارزمية الذكية: ترتيب الطابور بصرياً بناءً على وضع العشوائي 🔥
    List<SongModel> displayQueue = baseQueue;
    if (provider.audioPlayer.shuffleModeEnabled && provider.audioPlayer.effectiveIndices != null) {
      // لو العشوائي شغال، بنرتب اللستة بناءً على الفهرس العشوائي بتاع محرك الصوت
      displayQueue = provider.audioPlayer.effectiveIndices!.map((index) {
        if (index < baseQueue.length) return baseQueue[index];
        return baseQueue.first;
      }).toList();
    }

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      height: MediaQuery.of(context).size.height * 0.65,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF11221A).withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 15, bottom: 20),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'طابور التشغيل',
                        style: GoogleFonts.tajawal(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      StreamBuilder<LoopMode>(
                        stream: provider.audioPlayer.loopModeStream,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.off;
                          IconData icon = Icons.repeat_rounded;
                          Color color = Colors.white54;

                          if (loopMode == LoopMode.all) {
                            color = AppColors.accent;
                          } else if (loopMode == LoopMode.one) {
                            icon = Icons.repeat_one_rounded;
                            color = AppColors.accent;
                          }

                          return IconButton(
                            icon: Icon(icon, color: color, size: 28),
                            onPressed: provider.toggleLoop,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    // بنستخدم اللستة الذكية هنا
                    itemCount: displayQueue.length, 
                    itemBuilder: (context, index) {
                      final song = displayQueue[index];
                      final isPlaying = provider.currentSong?.id == song.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            color: isPlaying ? AppColors.accent : Colors.white,
                            fontWeight: isPlaying
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          song.artist ?? 'غير معروف',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(color: Colors.white54),
                        ),
                        trailing: isPlaying
                            ? const Icon(
                                Icons.bar_chart_rounded,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          // لو داس على أغنية تانية، يكمل في نفس الطابور بدون مشاكل
                          if (!isPlaying) {
                            provider.playSong(song, queue: baseQueue);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}