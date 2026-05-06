import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart'; // 🔥 المكتبة الجديدة
import '../../providers/audio_provider.dart';
import '../../core/theme.dart';
import 'video_player_screen.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: const Color(0xFF11221A),
          onRefresh: () async => await provider.loadVideos(), 
          child: Column(
            children: [
              _buildHeader(provider),
              Expanded(
                child: provider.isVideosLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : provider.videos.isEmpty
                        ? _buildEmptyState()
                        : _buildVideoGrid(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AudioProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الفيديوهات', style: GoogleFonts.tajawal(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.accent, size: 28),
            color: const Color(0xFF11221A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onSelected: (value) => provider.setVideoSortOrder(value),
            itemBuilder: (context) => [
              _buildSortItem('date', 'الأحدث', Icons.calendar_today_rounded, provider.videoSortOrder),
              _buildSortItem('name', 'الاسم', Icons.sort_by_alpha_rounded, provider.videoSortOrder),
              _buildSortItem('size', 'الحجم', Icons.sd_storage_rounded, provider.videoSortOrder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(AudioProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10).copyWith(bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: provider.videos.length,
      itemBuilder: (context, index) {
        final video = provider.videos[index];
        return _buildVideoCard(context, video);
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, dynamic video) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoPath: video.data),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 🔥 استخدام الـ Helper Widget المخصص للـ Thumbnail 🔥
                    VideoThumbnailWidget(videoPath: video.data),
                    
                    if (video.duration != null)
                      Positioned(
                        bottom: 8, right: 8,
                        child: _buildDurationBadge(video.duration!),
                      ),
                  ],
                ),
              ),
              _buildVideoInfo(video.title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo(String title) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, 
        style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildDurationBadge(int durationMs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
      child: Text(_formatDuration(Duration(milliseconds: durationMs)),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text('لم يتم العثور على فيديوهات', 
      style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 18)));
  }

  PopupMenuItem<String> _buildSortItem(String value, String title, IconData icon, String currentOrder) {
    final isSelected = value == currentOrder;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.accent : Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.tajawal(color: isSelected ? AppColors.accent : Colors.white, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds";
  }
}

// 🔥 ويدجت احترافي لتوليد وعرض الـ Thumbnail في الخلفية 🔥
class VideoThumbnailWidget extends StatelessWidget {
  final String videoPath;
  const VideoThumbnailWidget({super.key, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 250, // تقليل الحجم لسرعة العرض
        quality: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: Colors.black26,
          child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white24, size: 50),
        );
      },
    );
  }
}