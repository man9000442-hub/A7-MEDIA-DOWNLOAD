import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'add_to_playlist_sheet.dart'; 

class OptionsSheet extends StatelessWidget {
  final SongModel song; 
  final bool isFromPlayer; // 🔥 متغير بيحدد إحنا فاتحين القائمة منين 🔥

  // خليناها false كافتراضي عشان اللي بره ميشوفش السرعة والمؤقت
  const OptionsSheet({super.key, required this.song, this.isFromPlayer = false}); 

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: const Color(0xFF11221A).withValues(alpha: 0.85), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5))),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(margin: const EdgeInsets.only(top: 15, bottom: 20), width: 50, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),

                  // 1. الهيدر
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: Row(
                      children: [
                        Container(height: 60, width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)]), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white54))))),
                        const SizedBox(width: 15),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), Text(song.artist ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(fontSize: 14, color: Colors.white60))])),
                      ],
                    ),
                  ),
                  
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),

                  // 2. قائمة الخيارات
                  _buildOptionItem(icon: Icons.playlist_add_rounded, title: 'إضافة لقائمة تشغيل', onTap: () {
                    Navigator.pop(context); 
                    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, elevation: 0, barrierColor: Colors.black.withValues(alpha: 0.5), builder: (context) => AddToPlaylistSheet(songIds: [song.id]));
                  }),
                  
                  _buildOptionItem(icon: Icons.share_rounded, title: 'مشاركة (Share)', onTap: () {
                    Navigator.pop(context);
                    provider.shareSong(song);
                  }),

                  // 🔥 الخيارات دي هتظهر بس لو إحنا جوه المشغل الكبير 🔥
                  if (isFromPlayer) ...[
                    _buildOptionItem(icon: Icons.speed_rounded, title: 'سرعة التشغيل (Speed)', onTap: () {
                      Navigator.pop(context);
                      _showSpeedDialog(context, provider); 
                    }),
                    _buildOptionItem(icon: Icons.timer_rounded, title: 'مؤقت النوم (Sleep timer)', onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم إضافة المؤقت قريباً...'), backgroundColor: AppColors.accent));
                    }),
                  ],

                  _buildOptionItem(icon: Icons.delete_outline_rounded, title: 'حذف الأغنية', color: Colors.redAccent, onTap: () {
                    Navigator.pop(context);
                    provider.deleteSongs([song]); // ربط الحذف الحقيقي
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح الأغنية وإزالتها'), backgroundColor: Colors.redAccent));
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 2),
      onTap: onTap,
    );
  }

  void _showSpeedDialog(BuildContext context, AudioProvider provider) {
    // ... (نفس الكود القديم بتاع نافذة السرعة زي ما هو بدون تغيير)
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
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
                    children: speeds.map((speed) {
                      return ActionChip(
                        label: Text('${speed}x', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.black)),
                        backgroundColor: provider.audioPlayer.speed == speed ? AppColors.accent : Colors.white70,
                        onPressed: () { provider.setSpeed(speed); Navigator.pop(context); },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}