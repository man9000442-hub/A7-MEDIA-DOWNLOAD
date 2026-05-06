import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'providers/online_music_provider.dart'; // تأكد إن المسار صح حسب مشروعك
// استيراد المزودات (Providers)
import 'providers/media_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/settings_provider.dart';

// استيراد الشاشات
import 'ui/screens/home_layout.dart'; // 🔥 التعديل هنا: استدعاء الهيكل الأساسي بدلاً من MusicScreen
import 'ui/screens/splash_screen.dart'; // 🔥 التعديل هنا: استدعاء الهيكل الأساسي بدلاً من MusicScreen

// استيراد الألوان 
import 'core/theme.dart';

Future<void> main() async {
  // 1. التأكد من تهيئة الفلاتر بالكامل قبل تشغيل خدمات النظام (الخلفية)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة خدمة الصوت في الخلفية والإشعارات
  // يجب أن يتم استدعاؤها هنا قبل runApp
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.media_vault.channel.audio',
    androidNotificationChannelName: 'مشغل الموسيقى',
    androidNotificationOngoing: true, // يبقي الإشعار ثابتاً أثناء التشغيل
  );

  // 3. تشغيل التطبيق وتغليفه بالمزودات
  runApp(
    MultiProvider(
      providers: [
        // مزود عمليات التحميل من يوتيوب
        ChangeNotifierProvider(create: (_) => MediaProvider()), 
        // مزود مشغل الموسيقى المحلي
        ChangeNotifierProvider(create: (_) => AudioProvider()), 
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OnlineMusicProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Media Vault',
      // ضبط الثيم ليكون مظلماً وأنيقاً ليتناسب مع تصميمنا
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background, 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
        ),
      ),
      // 🔥 التعديل الأهم: جعل الهيكل الأساسي (HomeLayout) هو بداية التطبيق 🔥
      home: const SplashScreen(), 
    );
  }
}