import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final List<int> songIds;

  const AddToPlaylistSheet({super.key, required this.songIds});

  // 🔥 النافذة الزجاجية لإنشاء قائمة جديدة (بالألوان الأساسية) 🔥
  void _showGlassAddPlaylistDialog(BuildContext context, AudioProvider provider) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F13).withValues(alpha: 0.8), // لون الخلفية الأساسي
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5)
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('قائمة تشغيل جديدة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  style: GoogleFonts.tajawal(color: Colors.white),
                  autofocus: true, // يفتح الكيبورد تلقائي
                  decoration: InputDecoration(
                    hintText: 'اسم القائمة...',
                    hintStyle: GoogleFonts.tajawal(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black45,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 16))
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent, // البنفسجي النيون
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          final newName = controller.text.trim();
                          provider.createPlaylist(newName);
                          // إضافة الأغاني المحددة للقائمة الجديدة فوراً
                          for (int id in songIds) {
                            provider.addSongToPlaylist(newName, id);
                          }
                          Navigator.pop(context); // قفل النافذة
                          Navigator.pop(context); // قفل الشيت
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('تم الإنشاء والإضافة بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.accent,
                          ));
                        }
                      },
                      child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);
    final playlists = provider.customPlaylists.keys.toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F13).withValues(alpha: 0.9), // الأسود العميق
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5)
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('إضافة إلى قائمة تشغيل', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // زر إنشاء قائمة جديدة
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_rounded, color: AppColors.accent),
                ),
                title: Text('إنشاء قائمة جديدة', style: GoogleFonts.tajawal(fontSize: 18, color: AppColors.accent, fontWeight: FontWeight.bold)),
                onTap: () => _showGlassAddPlaylistDialog(context, provider),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

              // عرض القوائم الحالية لاختيار واحدة منها
              Expanded(
                child: playlists.isEmpty
                    ? Center(child: Text('لا توجد قوائم، أنشئ واحدة الآن!', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 16)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlistName = playlists[index];
                          final songCount = provider.customPlaylists[playlistName]!.length;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.queue_music_rounded, color: Colors.white),
                            ),
                            title: Text(playlistName, style: GoogleFonts.tajawal(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('$songCount أغنية', style: GoogleFonts.tajawal(color: Colors.white54)),
                            onTap: () {
                              // إضافة كل الأغاني اللي اليوزر اختارها للقائمة دي
                              for (int id in songIds) {
                                provider.addSongToPlaylist(playlistName, id);
                              }
                              Navigator.pop(context); // قفل الشيت بعد الإضافة
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تمت الإضافة لـ $playlistName بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                                backgroundColor: AppColors.accent,
                              ));
                            },
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