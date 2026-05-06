import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'options_sheet.dart'; 
import 'player_screen.dart'; 

class PlaylistDetailsScreen extends StatelessWidget {
  final String playlistName;
  const PlaylistDetailsScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    final songIds = provider.customPlaylists[playlistName] ?? [];
    final playlistSongs = provider.songs.where((song) => songIds.contains(song.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity, padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 30),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5))),
                child: Column(
                  children: [
                    Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)))),
                    const Icon(Icons.queue_music_rounded, color: AppColors.accent, size: 60),
                    const SizedBox(height: 10),
                    Text(playlistName, style: GoogleFonts.tajawal(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${playlistSongs.length} أغنية', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: playlistSongs.isEmpty ? Center(child: Text('القائمة فارغة، أضف أغاني لتستمتع بها!', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 18)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 100, top: 15), itemCount: playlistSongs.length,
                        itemBuilder: (context, index) {
                          final song = playlistSongs[index];
                          final isPlaying = provider.currentSong?.id == song.id;
                          return _buildAnimatedSongItem(context, provider, song, playlistSongs, isPlaying);
                        },
                      ),
              ),
            ],
          ),
          if (provider.currentSong != null)
            Positioned(
              bottom: 15, left: 15, right: 15,
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: const Offset(0, 100), end: Offset.zero), duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic,
                builder: (context, offset, child) => Transform.translate(offset: offset, child: child),
                child: _buildGlassMiniPlayer(context, provider),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSongItem(BuildContext context, AudioProvider provider, SongModel song, List<SongModel> currentQueue, bool isPlaying) {
    return InkWell(
      onTap: () {
        // 🔥 تم الحل هنا: بنبعت الأغنية والقائمة الصح بدل الـ index القديم 🔥
        if (!isPlaying) provider.playSong(song, queue: currentQueue); 
        else showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, elevation: 0, barrierColor: Colors.transparent, builder: (context) => const PlayerScreen());
      },
      splashColor: Colors.transparent, highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6), padding: EdgeInsets.all(isPlaying ? 8 : 4),
        decoration: BoxDecoration(color: isPlaying ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: isPlaying ? Colors.white.withValues(alpha: 0.15) : Colors.transparent, width: 1)),
        child: Row(
          children: [
            Container(height: 55, width: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: isPlaying ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 10)] : []), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(color: Colors.white.withValues(alpha: 0.05), child: const Icon(Icons.music_note, color: Colors.white24))))),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w800, color: isPlaying ? Colors.white : Colors.white.withValues(alpha: 0.85))), const SizedBox(height: 4), Text(song.artist ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 13, color: isPlaying ? Colors.white70 : Colors.white54, fontWeight: FontWeight.w500))])),
            isPlaying ? const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.bar_chart_rounded, color: AppColors.accent))
                : IconButton(icon: const Icon(Icons.more_vert, color: Colors.white30), onPressed: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, elevation: 0, barrierColor: Colors.black.withValues(alpha: 0.5), builder: (context) => OptionsSheet(song: song))),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassMiniPlayer(BuildContext context, AudioProvider provider) {
    final currentSong = provider.currentSong!;
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, elevation: 0, barrierColor: Colors.transparent, builder: (context) => const PlayerScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70, clipBehavior: Clip.hardEdge, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 48, width: 48, child: QueryArtworkWidget(id: currentSong.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white, size: 20))))),
                      const SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(currentSong.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 2), Text(currentSong.artist ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500))])),
                      StreamBuilder<bool>(stream: provider.audioPlayer.playingStream, builder: (context, snapshot) => IconButton(icon: Icon(snapshot.data ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32), onPressed: provider.togglePlayPause)),
                      IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32), onPressed: provider.playNext),
                    ],
                  ),
                ),
                Positioned(bottom: 0, left: 0, right: 0, height: 3, child: StreamBuilder<Duration>(stream: provider.audioPlayer.positionStream, builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero; final duration = provider.audioPlayer.duration ?? const Duration(milliseconds: 1);
                  double progress = (position.inMilliseconds / duration.inMilliseconds); if (progress.isNaN || progress.isInfinite) progress = 0.0;
                  return LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.85)));
                })),
              ],
            ),
          ),
        ),
      ),
    );
  }
}