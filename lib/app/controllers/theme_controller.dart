import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();

  final RxBool _isDarkMode = false.obs;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    _prefs = Get.find<SharedPreferences>();
    _isDarkMode.value = _prefs.getBool('isDarkMode') ?? false;
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(themeMode);
    await _prefs.setBool('isDarkMode', _isDarkMode.value);
    
    Get.snackbar(
      'Theme Changed',
      'Switched to ${_isDarkMode.value ? 'Dark' : 'Light'} mode',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode.value = isDark;
    Get.changeThemeMode(themeMode);
    await _prefs.setBool('isDarkMode', isDark);
  }
}