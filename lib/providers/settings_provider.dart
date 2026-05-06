import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String apiPassword = '';
  // حط الـ IP بتاع جهازك هنا (مثال: 192.168.1.5) ولو رفعت السيرفر حط الدومين
  String serverUrl = 'https://socialist-kameko-ta3almm-18a6b3e5.koyeb.app'; 

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    apiPassword = prefs.getString('api_password') ?? '';
    serverUrl = prefs.getString('server_url') ?? 'https://socialist-kameko-ta3almm-18a6b3e5.koyeb.app';
    notifyListeners();
  }

  Future<void> saveSettings(String password, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_password', password);
    await prefs.setString('server_url', url);
    apiPassword = password;
    serverUrl = url;
    notifyListeners();
  }
}