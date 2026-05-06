import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/media_provider.dart';

class DownloadSheet extends StatelessWidget {
  final String videoUrl;
  final String videoTitle;
  const DownloadSheet({super.key, required this.videoUrl, required this.videoTitle});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MediaProvider>(context);

    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('اختر الصيغة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),

            if (provider.isDownloading) ...[
              // نعرض رسالة الحالة فقط بدون شريط تحميل لأن النظام بيعرضه
              Text(provider.downloadStatusMessage ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.accent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
            ] else ...[
              const Text('فيديو (MP4)', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              _buildOptionTile(
                title: 'تحميل كـ فيديو',
                icon: Icons.video_library,
                // 🔥 صلحنا الخطأ هنا: شيلنا الـ context 🔥
                onTap: () => provider.startDownload(videoUrl, videoTitle, isAudioOnly: false),
              ),
              
              const Divider(color: Colors.white24, height: 30),
              
              const Text('صوت (MP3)', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              _buildOptionTile(
                title: 'تحميل كـ صوت',
                icon: Icons.music_note,
                // 🔥 صلحنا الخطأ هنا: شيلنا الـ context 🔥
                onTap: () => provider.startDownload(videoUrl, videoTitle, isAudioOnly: true),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onTap: onTap,
    );
  }
}