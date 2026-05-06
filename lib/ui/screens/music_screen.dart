import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'options_sheet.dart'; 
import 'add_to_playlist_sheet.dart'; 
import 'premium_detail_screen.dart'; 

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  int _selectedIndex = 0;
  final List<String> _categories = ['الأغاني', 'الفنانين', 'المفضلة', 'قوائم التشغيل'];
  
  final Set<int> _selectedSongs = {}; 
  bool get _isSelectionMode => _selectedSongs.isNotEmpty;

  // 🔥 متغيرات البحث 🔥
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int songId) => setState(() => _selectedSongs.contains(songId) ? _selectedSongs.remove(songId) : _selectedSongs.add(songId));
  void _clearSelection() => setState(() => _selectedSongs.clear());

  // 🔥 دالة فلترة الأغاني بناءً على البحث 🔥
  List<SongModel> _getFilteredSongs(List<SongModel> allSongs) {
    if (_searchQuery.trim().isEmpty) return allSongs;
    final query = _searchQuery.trim().toLowerCase();
    return allSongs.where((song) {
      final titleMatch = song.title.toLowerCase().contains(query);
      final artistMatch = song.artist?.toLowerCase().contains(query) ?? false;
      return titleMatch || artistMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    final filteredSongs = _getFilteredSongs(provider.songs); // تطبيق الفلتر

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isSelectionMode ? _buildSelectionBar() : _buildGlassCategories(),
          
          // 🔥 إظهار شريط البحث فقط إذا لم نكن في وضع التحديد 🔥
          if (!_isSelectionMode) ...[
            const SizedBox(height: 15),
            _buildSearchBar(),
          ],

          const SizedBox(height: 15),
          
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _buildCurrentView(provider, filteredSongs), // تمرير القائمة المفلترة
          ),
        ],
      ),
    );
  }

  // 🔥 ويدجت شريط البحث الزجاجي 🔥
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: GoogleFonts.tajawal(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن أغنية، فنان، أو قائمة...',
            hintStyle: GoogleFonts.tajawal(color: Colors.white54),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      FocusScope.of(context).unfocus(); // إخفاء الكيبورد
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final selectedMediaList = provider.songs.where((s) => _selectedSongs.contains(s.id)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5)),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: _clearSelection),
                const SizedBox(width: 5),
                Text('${_selectedSongs.length} محدد', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.share_rounded, color: Colors.white, size: 24), onPressed: () { provider.shareMultipleSongs(selectedMediaList); _clearSelection(); }),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26), onPressed: () {
                  showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF09090E), title: Text('تأكيد الحذف', style: GoogleFonts.tajawal(color: Colors.white)), content: Text('هل أنت متأكد أنك تريد مسح ${_selectedSongs.length} عنصر؟', style: GoogleFonts.tajawal(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.white54))), TextButton(onPressed: () { provider.deleteSongs(selectedMediaList); Navigator.pop(context); _clearSelection(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم المسح بنجاح'), backgroundColor: Colors.redAccent)); }, child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.redAccent, fontWeight: FontWeight.bold)))]));
                }),
                IconButton(icon: const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 28), onPressed: () { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, elevation: 0, barrierColor: Colors.black.withValues(alpha: 0.5), builder: (context) => AddToPlaylistSheet(songIds: _selectedSongs.toList())).then((_) => _clearSelection()); }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () { setState(() => _selectedIndex = index); _clearSelection(); }, 
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(30), border: Border.all(color: isSelected ? AppColors.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05), width: 1.5)),
                    child: Text(_categories[index], style: GoogleFonts.tajawal(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: isSelected ? 16 : 14)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentView(AudioProvider provider, List<SongModel> filteredSongs) {
    if (_selectedIndex == 0) return _buildSongsView(provider, filteredSongs);
    if (_selectedIndex == 1) return _buildArtistsView(filteredSongs); // نمرر الأغاني المفلترة
    if (_selectedIndex == 2) {
      final favoriteSongs = filteredSongs.where((song) => provider.isFavorite(song.id)).toList();
      if (favoriteSongs.isEmpty) return Center(child: Text('لم يتم العثور على نتائج مفضلة', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 18)));
      return _buildSongsListWidget(favoriteSongs, provider);
    }
    return _buildPlaylistsView(provider); 
  }

  Widget _buildSongsView(AudioProvider provider, List<SongModel> filteredSongs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${filteredSongs.length} نتيجة', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white54)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: AppColors.accent, size: 26), color: const Color(0xFF11221A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) => provider.setSongSortOrder(value),
                itemBuilder: (context) => [
                  _buildSortItem('date_added', 'الأحدث إضافة', Icons.fiber_new_rounded, provider.songSortOrder), 
                  _buildSortItem('name', 'الاسم', Icons.sort_by_alpha_rounded, provider.songSortOrder), 
                  _buildSortItem('artist', 'الفنان', Icons.person_rounded, provider.songSortOrder),
                  _buildSortItem('size', 'الحجم', Icons.sd_storage_rounded, provider.songSortOrder), 
                  _buildSortItem('duration', 'المدة', Icons.access_time_rounded, provider.songSortOrder),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildSongsListWidget(filteredSongs, provider)),
      ],
    );
  }

  Widget _buildArtistsView(List<SongModel> filteredSongs) {
    final Map<String, List<SongModel>> artistGroups = {};
    for (var song in filteredSongs) {
      String rawArtist = song.artist ?? '';
      if (rawArtist == '<unknown>' || rawArtist.trim().isEmpty) rawArtist = 'غير معروف';
      String standardizedArtists = rawArtist.replaceAll(RegExp(r'\s+&\s+'), ',').replaceAll(RegExp(r'\s+feat\.?\s+', caseSensitive: false), ',').replaceAll(RegExp(r'\s+ft\.?\s+', caseSensitive: false), ',');
      List<String> individualArtists = standardizedArtists.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (individualArtists.isEmpty) individualArtists = ['غير معروف'];
      for (String artist in individualArtists) {
        if (!artistGroups.containsKey(artist)) artistGroups[artist] = [];
        if (!artistGroups[artist]!.any((s) => s.id == song.id)) artistGroups[artist]!.add(song);
      }
    }

    final artists = artistGroups.keys.toList()..sort();
    if (artists.isEmpty) return Center(child: Text('لم يتم العثور على فنانين', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 18)));

    return ListView.builder(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 120, top: 5), itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final artistSongs = artistGroups[artist]!;
        final firstSongId = artistSongs.isNotEmpty ? artistSongs.first.id : null; 

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              height: 50, width: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.accent.withValues(alpha: 0.2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: firstSongId != null 
                    ? QueryArtworkWidget(id: firstSongId, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.mic_external_on_rounded, color: AppColors.accent))
                    : const Icon(Icons.mic_external_on_rounded, color: AppColors.accent),
              ),
            ),
            title: Text(artist, style: GoogleFonts.tajawal(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)), 
            subtitle: Text('${artistSongs.length} أغنية', style: GoogleFonts.tajawal(color: Colors.white54)), 
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 18),
            onTap: () => Navigator.of(context).push(PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => PremiumDetailScreen(title: artist, songs: artistSongs, isPlaylist: false), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child))),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsView(AudioProvider provider) {
    // 🔥 تطبيق البحث على أسماء قوائم التشغيل 🔥
    final query = _searchQuery.trim().toLowerCase();
    final playlists = provider.customPlaylists.keys.where((name) => name.toLowerCase().contains(query)).toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('قوائمي', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent, size: 28), onPressed: () => _showGlassAddPlaylistDialog(context, provider)),
            ],
          ),
        ),
        if (playlists.isEmpty)
          Expanded(child: Center(child: Text('لم يتم العثور على قوائم تشغيل', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 18))))
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 120, top: 5), itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlistName = playlists[index];
                final songIds = provider.customPlaylists[playlistName]!;
                final playlistSongs = provider.songs.where((s) => songIds.contains(s.id)).toList();
                final firstSongId = playlistSongs.isNotEmpty ? playlistSongs.first.id : null; 

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
                    leading: Container(
                      height: 50, width: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withValues(alpha: 0.1)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: firstSongId != null 
                            ? QueryArtworkWidget(id: firstSongId, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.queue_music_rounded, color: Colors.white))
                            : const Icon(Icons.queue_music_rounded, color: Colors.white),
                      ),
                    ), 
                    title: Text(playlistName, style: GoogleFonts.tajawal(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)), 
                    subtitle: Text('${playlistSongs.length} أغنية', style: GoogleFonts.tajawal(color: Colors.white54)), 
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 18),
                    onTap: () => Navigator.of(context).push(PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => PremiumDetailScreen(title: playlistName, songs: playlistSongs, isPlaylist: true), transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child))),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showGlassAddPlaylistDialog(BuildContext context, AudioProvider provider) {
    TextEditingController controller = TextEditingController();
    showDialog(
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
                Text('قائمة تشغيل جديدة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller, style: GoogleFonts.tajawal(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اسم القائمة...', hintStyle: GoogleFonts.tajawal(color: Colors.white54),
                    filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
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
                          provider.createPlaylist(controller.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      child: Text('إنشاء', style: GoogleFonts.tajawal(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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

  PopupMenuItem<String> _buildSortItem(String value, String title, IconData icon, String currentOrder) {
    final isSelected = value == currentOrder;
    return PopupMenuItem<String>(value: value, child: Row(children: [Icon(icon, color: isSelected ? AppColors.accent : Colors.white70, size: 20), const SizedBox(width: 10), Text(title, style: GoogleFonts.tajawal(color: isSelected ? AppColors.accent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))]));
  }

  Widget _buildSongsListWidget(List<SongModel> songsToDisplay, AudioProvider provider) {
    if (songsToDisplay.isEmpty) return Center(child: Text('لم يتم العثور على موسيقى', style: GoogleFonts.tajawal(color: Colors.white54)));
    return ListView.builder(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 120, top: 5), itemCount: songsToDisplay.length,
      itemBuilder: (context, index) {
        final song = songsToDisplay[index];
        final isPlaying = provider.currentSong?.id == song.id;
        return _buildAnimatedSongItem(context, provider, song, songsToDisplay, isPlaying);
      },
    );
  }

  Widget _buildAnimatedSongItem(BuildContext context, AudioProvider provider, SongModel song, List<SongModel> currentQueue, bool isPlaying) {
    final isSelected = _selectedSongs.contains(song.id);
    return InkWell(
      onLongPress: () => _toggleSelection(song.id),
      onTap: () { if (_isSelectionMode) _toggleSelection(song.id); else if (!isPlaying) provider.playSong(song, queue: currentQueue); }, 
      splashColor: Colors.transparent, highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6), padding: EdgeInsets.all(isPlaying ? 8 : 4),
        decoration: BoxDecoration(color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : (isPlaying ? Colors.white.withValues(alpha: 0.07) : Colors.transparent), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? AppColors.accent.withValues(alpha: 0.5) : (isPlaying ? Colors.white.withValues(alpha: 0.15) : Colors.transparent), width: 1), boxShadow: isPlaying && !_isSelectionMode ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))] : []),
        child: Row(
          children: [
            Container(height: 55, width: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: isPlaying ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 10)] : []), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(color: Colors.white.withValues(alpha: 0.05), child: const Icon(Icons.music_note, color: Colors.white24))))),
            const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w800, color: isPlaying ? Colors.white : Colors.white.withValues(alpha: 0.85))), const SizedBox(height: 4), Text(song.artist ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 13, color: isPlaying ? Colors.white70 : Colors.white54, fontWeight: FontWeight.w500))])),
            if (_isSelectionMode) Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? AppColors.accent : Colors.white54, size: 26)) else if (isPlaying) const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.bar_chart_rounded, color: AppColors.accent)) else IconButton(icon: const Icon(Icons.more_vert, color: Colors.white30), onPressed: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, elevation: 0, barrierColor: Colors.black.withValues(alpha: 0.5), builder: (context) => OptionsSheet(song: song))),
          ],
        ),
      ),
    );
  }
}