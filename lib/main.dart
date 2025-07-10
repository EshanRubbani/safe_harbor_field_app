import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_photos_controller.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_questionaire_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/controllers/auth_controller.dart';
import 'app/themes/app_theme.dart';

import 'app/controllers/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'firebase_options.dart';
import 'app/controllers/inspection_reports_controller.dart';
import 'app/services/questionaire_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  
  await Get.putAsync(() => SharedPreferences.getInstance());
  
  
  Get.put(ThemeController(), permanent: true);
  Get.put(InspectionPhotosController(), permanent: true);
  Get.put(QuestionnaireController(), permanent: true);
  Get.put(InspectionReportsController(), permanent: true);
  Get.put(QuestionnaireService(), permanent: true);
  
  // Initialize AuthController last to prevent premature navigation
  Get.put(AuthController(), permanent: true);

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
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
    );
  }
}
