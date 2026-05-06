import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/online_music_provider.dart';
// 🔥 تم استدعاء شيت التحميل عشان نستخدمه هنا
import '../widgets/download_sheet.dart'; 

class OnlineExploreScreen extends StatefulWidget {
  const OnlineExploreScreen({super.key});

  @override
  State<OnlineExploreScreen> createState() => _OnlineExploreScreenState();
}

class _OnlineExploreScreenState extends State<OnlineExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnlineMusicProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildSearchBar(provider),
      ),
      body: Column(
        children: [
          if (provider.isBuffering)
            const LinearProgressIndicator(color: Colors.greenAccent),
            
          Expanded(
            child: provider.isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : provider.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(provider.errorMessage!, 
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                        ),
                      )
                    : provider.searchResults.isEmpty
                        ? const Center(
                            child: Text('ابحث عن أي أغنية أو مقطع صوتي 🎧', 
                            style: TextStyle(color: Colors.white54, fontSize: 18)))
                        : _buildSearchResults(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(OnlineMusicProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'بحث يوتيوب...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Colors.greenAccent),
            onPressed: () {
              FocusScope.of(context).unfocus();
              provider.search(_searchController.text);
            },
          ),
        ),
        onSubmitted: (value) => provider.search(value),
      ),
    );
  }

  Widget _buildSearchResults(OnlineMusicProvider provider) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final video = provider.searchResults[index];
        final isPlaying = provider.currentPlayingVideo?.id == video.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              video.thumbnails.lowResUrl, 
              width: 60, height: 60, fit: BoxFit.cover,
            ),
          ),
          title: Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPlaying ? Colors.greenAccent : Colors.white,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(video.author, style: const TextStyle(color: Colors.white54)),
          // 🔥 هنا التغيير: حطينا Row عشان ندمج زرار التحميل مع أيقونة التشغيل
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // مهمة عشان ميأخدش مساحة زيادة
            children: [
              // زر التحميل الجديد 📥
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white70),
                onPressed: () {
                  // فتح شيت التحميل بنفس الطريقة اللي في الـ ExploreScreen
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => DownloadSheet(
                      videoUrl: "https://youtu.be/${video.id}", 
                      videoTitle: video.title,
                    ),
                  );
                },
              ),
              // أيقونة التشغيل الأصلية ▶️
              Icon(
                isPlaying ? Icons.multitrack_audio_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.greenAccent : Colors.white54,
              ),
            ],
          ),
          onTap: () => provider.playAudioOnline(video),
        );
      },
    );
  }
}