import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/views/Login/login_view.dart';
import 'package:safe_harbor_field_app/app/views/home/home_view.dart';
import 'package:safe_harbor_field_app/app/views/inspection/inspection_photos_view.dart';
import 'package:safe_harbor_field_app/app/views/inspection/inspection_questionaire_view.dart';
import 'package:safe_harbor_field_app/app/views/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => SplashView(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.inspection_photos,
      page: () => InspectionPhotosView(),
    ),
    GetPage(
      name: AppRoutes.inspection_questionaire,
      page: () => InspectionQuestionaireView(),
    ),
  ];
}
