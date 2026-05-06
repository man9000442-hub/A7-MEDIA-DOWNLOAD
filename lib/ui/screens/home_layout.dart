import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'music_screen.dart'; 
import 'player_screen.dart';
import 'explore_screen.dart'; 
import 'videos_screen.dart';  
import 'settings_screen.dart'; 
import 'online_explore_screen.dart'; // 🔥 تم إضافة استدعاء شاشة الأون لاين

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0; 

  // 🔥 لستة الشاشات الحقيقية بالكامل بعد إضافة الأونلاين 🔥
  final List<Widget> _screens = [
    const MusicScreen(),                  // 0. محلي
    const OnlineExploreScreen(),          // 1. أون لاين (تم الربط بالشاشة الحقيقية!) 🔥
    ExploreScreen(),                      // 2. التحميل 
    const VideosScreen(),                 // 3. الفيديوهات 
    const SettingsScreen(),               // 4. الإعدادات 
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildGlobalHeader(), 
            const SizedBox(height: 15),
            
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),

                  if (provider.currentSong != null && _currentIndex != 3) 
                    Positioned(
                      bottom: 10, left: 15, right: 15,
                      child: _buildGlassMiniPlayer(context, provider),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassBottomBar(),
    );
  }

  Widget _buildGlobalHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 36),
              const SizedBox(width: 4),
              Text('A7', style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: Text('MEDIA', style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 1))),
            ],
          ),
          Container(
            height: 45, width: 45,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)),
            child: IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22), onPressed: () => setState(() => _currentIndex = 4)), 
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(top: 10, bottom: 15, left: 10, right: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF11221A).withValues(alpha: 0.9), 
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, 'محلي', Icons.folder_rounded),
              _buildNavItem(1, 'أون لاين', Icons.public_rounded),
              _buildNavItem(2, 'التحميل', Icons.download_rounded),
              _buildNavItem(3, 'فيديوهات', Icons.play_circle_filled_rounded),
              _buildNavItem(4, 'إعدادات', Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent, 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : Colors.white54, size: 26),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.tajawal(color: isSelected ? AppColors.accent : Colors.white54, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
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

// كلاس الـ Placeholder ممكن نسيبه زي ما هو احتياطي لو احتجت تعمله لأي شاشة تانية في المستقبل
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('شاشة $title قيد التطوير 🛠️', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}