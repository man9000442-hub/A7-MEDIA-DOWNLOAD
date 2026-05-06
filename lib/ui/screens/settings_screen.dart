import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _passController.text = settings.apiPassword;
    _urlController.text = settings.serverUrl;
  }

  // 🔥 الدالة دلوقت بتفتح اللينك في المتصفح الخارجي 🔥
  void _launchPortfolio() async {
    final Uri url = Uri.parse('https://man9000442-hub.github.io/Eng-Abdelrahman-prot/');
    
    // استخدام LaunchMode.externalApplication لفتحه خارج التطبيق
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, 
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 👤 الجزء العلوي: خانة المصمم (Eng Abdelrahman)
            _buildDeveloperCard(),
            
            const SizedBox(height: 30),
            
            // 🛠️ الجزء السفلي: إعدادات الخادم
            _buildServerSettingsCard(settings),
            
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.accent,
            child: Icon(Icons.code_rounded, size: 50, color: Colors.black),
          ),
          const SizedBox(height: 15),
          Text(
            'Software Engineer',
            style: GoogleFonts.tajawal(
              color: AppColors.accent, 
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Abdelrahman Tarek',
            style: GoogleFonts.tajawal(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          // زرار البروفايل (يفتح في المتصفح الخارجي)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchPortfolio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Colors.white12), // تصحيح الـ side
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 20),
              label: Text('Visit My Portfolio', 
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSettingsCard(SettingsProvider settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_input_component_rounded, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text('إعدادات الخادم', 
                    style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 25),
              _buildField(_urlController, 'رابط الخادم (Server URL)', Icons.link_rounded),
              const SizedBox(height: 15),
              _buildField(_passController, 'كلمة المرور (API Key)', Icons.lock_person_rounded, isPass: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    settings.saveSettings(_passController.text.trim(), _urlController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الإعدادات!'), backgroundColor: AppColors.accent)
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.save_rounded, color: Colors.black),
                  label: Text('حفظ التغييرات', 
                    style: GoogleFonts.tajawal(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.tajawal(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.accent.withValues(alpha: 0.6), size: 20),
        filled: true,
        fillColor: Colors.black38,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }
}