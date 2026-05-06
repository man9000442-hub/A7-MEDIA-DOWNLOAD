import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:async';
import 'home_layout.dart'; // غيرها لاسم الشاشة الرئيسية عندك

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتقال للشاشة الرئيسية بعد 4 ثواني (وقت كافي للأنيميشن)
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeLayout()), // الشاشة اللي بتفتح بعد التحميل
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // خلفية سوداء بالكامل
      body: Stack(
        children: [
          // الجزء اللي في النص: الأيقونة ودايرة التحميل
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اللوجو النيون بتاعك
                Image.asset(
                  'assets/images/icon.png', // تأكد من المسار
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 30),
                // دايرة التحميل
                const CircularProgressIndicator(
                  color: Color(0xFFBC00FF), // لون بنفسجي نيون ماتش مع اللوجو
                  strokeWidth: 3,
                ),
              ],
            ),
          ),

          // الجزء اللي تحت خالص: أنيميشن الكتابة
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Designed and Developed by Abdelrahman Tarek',
                    textStyle: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                    speed: const Duration(milliseconds: 100), // سرعة الكتابة
                  ),
                ],
                totalRepeatCount: 1, // يكتبها مرة واحدة بس
                displayFullTextOnTap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}