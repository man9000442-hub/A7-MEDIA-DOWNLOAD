import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/media_provider.dart';
import '../widgets/download_sheet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _urlController = TextEditingController();
  int _currentTab = 0; 
  List<FileSystemEntity> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    try {
      final dir = Directory('/storage/emulated/0/Download/A7_Media');
      if (await dir.exists()) {
        setState(() {
          _downloadedFiles = dir.listSync().where((file) {
            final ext = file.path.split('.').last.toLowerCase();
            return ext == 'mp3' || ext == 'm4a' || ext == 'mp4';
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MediaProvider>(context);

    if (_currentTab == 1 && !provider.isDownloading) {
      _loadDownloadedFiles();
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildGlassTabs(), 
            const SizedBox(height: 20),
            Expanded(
              child: _currentTab == 0
                  ? _buildExploreView(provider)
                  : _buildDownloadsView(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(30),
        child: Row(
          children: [
            Expanded(child: _buildTabButton(0, 'استكشاف', Icons.search_rounded)),
            Expanded(child: _buildTabButton(1, 'التحميلات', Icons.download_done_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTab = index);
        if (index == 1) _loadDownloadedFiles();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.tajawal(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreView(MediaProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: GoogleFonts.tajawal(color: Colors.white),
                    decoration: InputDecoration(hintText: 'ضع رابط يوتيوب هنا...', hintStyle: GoogleFonts.tajawal(color: Colors.grey), border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.accent, size: 28),
                  onPressed: () {
                    provider.searchVideo(_urlController.text);
                    FocusScope.of(context).unfocus();
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : provider.errorMessage != null
                      ? Text(provider.errorMessage!, style: GoogleFonts.tajawal(color: Colors.redAccent, fontSize: 16))
                      : provider.currentMedia != null
                          ? _buildMediaCard(context, provider.currentMedia!)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.youtube_searched_for_rounded, size: 80, color: Colors.white24),
                                const SizedBox(height: 15),
                                Text('أدخل رابط يوتيوب للبدء 🚀', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 18)),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, media) {
    return GlassContainer(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(media.thumbnailUrl, fit: BoxFit.cover, height: 200, width: double.infinity),
          ),
          const SizedBox(height: 15),
          Text(media.title, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(media.author, style: GoogleFonts.tajawal(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => DownloadSheet(videoUrl: "https://youtu.be/${media.id}", videoTitle: media.title));
            },
            icon: const Icon(Icons.download_rounded, color: Colors.black),
            label: Text('خيارات التحميل', style: GoogleFonts.tajawal(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildDownloadsView(MediaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.isDownloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.cloud_download_rounded, color: AppColors.accent), const SizedBox(width: 10), Text('التحميل يعمل في الخلفية...', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 15),
                  Text(provider.downloadStatusMessage ?? '', style: GoogleFonts.tajawal(color: AppColors.accent, fontSize: 14)),
                ],
              ),
            ),
          ),
          
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10), child: Text('الملفات المكتملة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),

        Expanded(
          child: _downloadedFiles.isEmpty
              ? Center(child: Text('لا توجد ملفات محملة حتى الآن', style: GoogleFonts.tajawal(color: Colors.white54)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _downloadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _downloadedFiles[index];
                    final fileName = file.path.split('/').last;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                      child: ListTile(
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.music_note_rounded, color: AppColors.accent)),
                        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.tajawal(color: Colors.white)),
                        trailing: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}