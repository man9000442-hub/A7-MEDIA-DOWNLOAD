import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'player_screen.dart';
import 'options_sheet.dart';

// ==========================================
//    شاشة الـ Premium الموحدة (فنانين / قوائم تشغيل)
// ==========================================
class PremiumDetailScreen extends StatefulWidget {
  final String title;
  final List<SongModel> songs; 
  final bool isPlaylist; 

  const PremiumDetailScreen({super.key, required this.title, required this.songs, this.isPlaylist = false});

  @override
  State<PremiumDetailScreen> createState() => _PremiumDetailScreenState();
}

class _PremiumDetailScreenState extends State<PremiumDetailScreen> {
  late String currentTitle;

  @override
  void initState() {
    super.initState();
    currentTitle = widget.title;
  }

  // النافذة الزجاجية لتعديل اسم البلاي ليست
  Future<void> _showGlassEditDialog(BuildContext context, AudioProvider provider) async {
    TextEditingController controller = TextEditingController(text: currentTitle);
    await showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF11221A).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تعديل اسم القائمة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller, style: GoogleFonts.tajawal(color: Colors.white),
                  decoration: InputDecoration(hintText: 'اكتب الاسم الجديد...', hintStyle: GoogleFonts.tajawal(color: Colors.white54), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 16))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          provider.renamePlaylist(currentTitle, controller.text.trim());
                          setState(() => currentTitle = controller.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 شاشة إدارة الأغاني (إضافة أو إزالة) 🔥
  void _showAddSongsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManagePlaylistSongsSheet(playlistName: currentTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    
    // القراءة اللحظية عشان تتحدث فوراً
    List<SongModel> displaySongs = widget.songs;
    if (widget.isPlaylist) {
      final playlistSongIds = provider.customPlaylists[currentTitle] ?? [];
      displaySongs = provider.songs.where((s) => playlistSongIds.contains(s.id)).toList();
    }
    
    final firstSongId = displaySongs.isNotEmpty ? displaySongs.first.id : null;

    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent, elevation: 0, floating: true,
                leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 250, width: 250,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15))]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: firstSongId != null 
                              ? QueryArtworkWidget(id: firstSongId, type: ArtworkType.AUDIO, artworkWidth: 250, artworkHeight: 250, artworkFit: BoxFit.cover, size: 500, nullArtworkWidget: _buildPlaceholder())
                              : _buildPlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isPlaylist) const Icon(Icons.edit, color: Colors.transparent, size: 24), 
                          Expanded(child: Text(currentTitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
                          if (widget.isPlaylist) IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 24), onPressed: () => _showGlassEditDialog(context, provider)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text('${displaySongs.length} مقطع صوتي', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white54)),
                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                              icon: const Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: 28),
                              label: Text('تشغيل', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              onPressed: () { if (displaySongs.isNotEmpty) provider.playSong(displaySongs.first, queue: displaySongs); },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                              icon: const Icon(Icons.shuffle_rounded, color: AppColors.accent, size: 24),
                              label: Text('عشوائي', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              onPressed: () async {
                                if (displaySongs.isNotEmpty) {
                                  if (!provider.audioPlayer.shuffleModeEnabled) provider.toggleShuffle();
                                  provider.playSong(displaySongs.first, queue: displaySongs);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      // 🔥 زرار إضافة الأغاني الجديد (نفس تصميم الصورة بالضبط) 🔥
                      if (widget.isPlaylist) ...[
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () => _showAddSongsSheet(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Colors.white70, size: 28),
                                ),
                                const SizedBox(width: 15),
                                Text('إضافة مقاطع صوتية', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = displaySongs[index];
                    final isPlaying = provider.currentSong?.id == song.id;

                    return InkWell(
                      onTap: () { if (!isPlaying) provider.playSong(song, queue: displaySongs); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6), padding: EdgeInsets.all(isPlaying ? 8 : 4),
                        decoration: BoxDecoration(color: isPlaying ? Colors.white.withValues(alpha: 0.07) : Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: isPlaying ? Colors.white.withValues(alpha: 0.15) : Colors.transparent, width: 1)),
                        child: Row(
                          children: [
                            Container(height: 55, width: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(color: Colors.white.withValues(alpha: 0.05), child: const Icon(Icons.music_note, color: Colors.white24))))),
                            const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w800, color: isPlaying ? Colors.white : Colors.white.withValues(alpha: 0.85))), const SizedBox(height: 4), Text(song.artist ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 13, color: isPlaying ? Colors.white70 : Colors.white54, fontWeight: FontWeight.w500))])),
                            if (isPlaying) const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.bar_chart_rounded, color: AppColors.accent)) else IconButton(icon: const Icon(Icons.more_vert, color: Colors.white30), onPressed: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, elevation: 0, barrierColor: Colors.black.withValues(alpha: 0.5), builder: (context) => OptionsSheet(song: song))),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: displaySongs.length,
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)), 
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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.accent.withValues(alpha: 0.2),
      child: const Icon(Icons.music_note_rounded, color: AppColors.accent, size: 80),
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
                      const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(currentSong.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 2), Text(currentSong.artist ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500))])),
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

// ==========================================
// 🔥 كلاس اختيار الأغاني للقائمة (زجاجي شيك) 🔥
// ==========================================
class ManagePlaylistSongsSheet extends StatefulWidget {
  final String playlistName;
  const ManagePlaylistSongsSheet({super.key, required this.playlistName});

  @override
  State<ManagePlaylistSongsSheet> createState() => _ManagePlaylistSongsSheetState();
}

class _ManagePlaylistSongsSheetState extends State<ManagePlaylistSongsSheet> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AudioProvider>(context, listen: false);
    _selectedIds = Set.from(provider.customPlaylists[widget.playlistName] ?? []);
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    final allSongs = provider.songs;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(color: const Color(0xFF09090E).withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تعديل مقاطع القائمة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      onPressed: () {
                        provider.updatePlaylistSongs(widget.playlistName, _selectedIds.toList());
                        Navigator.pop(context);
                      },
                      child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: allSongs.length,
                  itemBuilder: (context, index) {
                    final song = allSongs[index];
                    final isSelected = _selectedIds.contains(song.id);

                    return InkWell(
                      onTap: () => _toggleSelection(song.id),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(15), border: Border.all(color: isSelected ? AppColors.accent.withValues(alpha: 0.4) : Colors.transparent)),
                        child: Row(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 50, width: 50, child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.music_note, color: Colors.white54))))),
                            const SizedBox(width: 15),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)), Text(song.artist ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 13, color: Colors.white54))])),
                            Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? AppColors.accent : Colors.white30, size: 28),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}