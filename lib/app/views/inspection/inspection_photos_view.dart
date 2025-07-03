import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_photos_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/utils/photos_section_widget.dart';

class InspectionPhotosView extends StatelessWidget {
  const InspectionPhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final InspectionPhotosController controller = Get.put(InspectionPhotosController());
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.background,
              colorScheme.background.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
          _buildHeaderCard(colorScheme, theme),
          
                    const SizedBox(height: 20),
          
                    // Primary Risk Photo Section
                    Obx(() => PhotoSection(
                      icon: Icons.warning_amber_rounded,
                      title: 'Primary Risk Photo',
                      description: 'A single photo highlighting the primary risk or concern.',
                      photoType: 'primary_risk',
                      photos: controller.primaryRiskPhotos,
                      photoCountText: controller.getPhotoCountText('primary_risk'),
                      isRequired: true,
                      hasError: controller.hasPrimaryRiskError.value,
                      errorMessage: controller.primaryRiskErrorMessage.value,
                      onAddPhoto: () => controller.showPhotoSourceDialog('primary_risk'),
                      onRemovePhoto: (index) => controller.removePhoto('primary_risk', index),
                    )),
          
                    // Front Elevation Photo Section
                    Obx(() => PhotoSection(
                      icon: Icons.home_outlined,
                      title: 'Front Elevation',
                      description: 'Photos of the front view of the property.',
                      photoType: 'front_elevation',
                      photos: controller.frontElevationPhotos,
                      photoCountText: controller.getPhotoCountText('front_elevation'),
                      onAddPhoto: () => controller.showPhotoSourceDialog('front_elevation'),
                      onRemovePhoto: (index) => controller.removePhoto('front_elevation', index),
                    )),
          
                    // Right Elevation Photo Section
                    Obx(() => PhotoSection(
                      icon: Icons.turn_right_rounded,
                      title: 'Right Elevation',
                      description: 'Photos of the right side view of the property.',
                      photoType: 'right_elevation',
                      photos: controller.rightElevationPhotos,
                      photoCountText: controller.getPhotoCountText('right_elevation'),
                      onAddPhoto: () => controller.showPhotoSourceDialog('right_elevation'),
                      onRemovePhoto: (index) => controller.removePhoto('right_elevation', index),
                    )),
          
                    // Rear Elevation Photo Section
                    Obx(() => PhotoSection(
                      icon: Icons.flip_camera_android_outlined,
                      title: 'Rear Elevation',
                      description: 'Photos of the rear view of the property.',
                      photoType: 'rear_elevation',
                      photos: controller.rearElevationPhotos,
                      photoCountText: controller.getPhotoCountText('rear_elevation'),
                      onAddPhoto: () => controller.showPhotoSourceDialog('rear_elevation'),
                      onRemovePhoto: (index) => controller.removePhoto('rear_elevation', index),
                    )),
          
                    // Roof Photo Section
                    Obx(() => PhotoSection(
                      icon: Icons.roofing_outlined,
                      title: 'Roof Photo',
                      description: 'Photos of the roof and roofing materials.',
                      photoType: 'roof',
                      photos: controller.roofPhotos,
                      photoCountText: controller.getPhotoCountText('roof'),
                      onAddPhoto: () => controller.showPhotoSourceDialog('roof'),
                      onRemovePhoto: (index) => controller.removePhoto('roof', index),
                    )),
          
                    // Additional Photos Section
                    Obx(() => PhotoSection(
                      icon: Icons.add_photo_alternate_outlined,
                      title: 'Additional Photos',
                      description: 'Any additional photos that may be relevant to the inspection.',
                      photoType: 'additional',
                      photos: controller.additionalPhotos,
                      photoCountText: controller.getPhotoCountText('additional'),
                      onAddPhoto: () => controller.showPhotoSourceDialog('additional'),
                      onRemovePhoto: (index) => controller.removePhoto('additional', index),
                    )),
          
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: Obx(() => controller.totalPhotoCount > 0 
        ? FloatingActionButton.extended(
            onPressed: () {
              if (controller.validateForm()) {
                Get.snackbar(
                  'Success', 
                  'All photos collected successfully! Total: ${controller.totalPhotoCount}',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                Get.toNamed(AppRoutes.inspection_questionaire);
              }
            },
            icon: Icon(Icons.arrow_forward_ios_rounded),
            label: Text('Next: Questionnaire'),
            
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          )
        : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      // margin: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.15),
                      colorScheme.secondary.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24.0),

              // Headline
              Text(
                "Photo Collection",
                style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontSize: 20,
                    ) ??
                    TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12.0),

              // Description text
              Text(
                "Capture photos for each category. Tap 'Add Photo' to use your device camera or select from gallery.",
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.6,
                      fontSize: 15,
                    ) ??
                    TextStyle(
                      fontSize: 15.0,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
