import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/themes/app_theme.dart';

import 'app/controllers/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Safe Harbor Field App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Get.find<ThemeController>().themeMode,
      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
    );
  }
}
