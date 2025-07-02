import 'package:flutter/material.dart';
import 'package:safe_harbor_field_app/app/utils/photos_section_widget.dart';
// Import the PhotoSection widget
// import 'photo_section_widget.dart';

class InspectionPhotosView extends StatelessWidget {
  const InspectionPhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card
                  header_card(colorScheme, theme),

                  const SizedBox(height: 20),

                  // Primary Risk Photo Section
                  PhotoSection(
                    icon: Icons.warning_amber_rounded,
                    title: 'Primary Risk Photo',
                    description: 'A single photo highlighting the primary risk or concern.',
                    photoCountText: '0 / 1 photo',
                    isRequired: true,
                    hasError: true,
                    errorMessage: 'Primary Risk Photo is required.',
                    onAddPhoto: () {
                      // Handle add photo for primary risk
                      print('Add Primary Risk Photo');
                    },
                  ),

                  // Front Elevation Photo Section
                  PhotoSection(
                    icon: Icons.home_outlined,
                    title: 'Front Elevation',
                    description: 'Photos of the front view of the property.',
                    photoCountText: '0 / 5 photos',
                    onAddPhoto: () {
                      // Handle add photo for front elevation
                      print('Add Front Elevation Photo');
                    },
                  ),

                  // Right Elevation Photo Section
                  PhotoSection(
                    icon: Icons.turn_right_rounded,
                    title: 'Right Elevation',
                    description: 'Photos of the right side view of the property.',
                    photoCountText: '0 / 5 photos',
                    onAddPhoto: () {
                      // Handle add photo for right elevation
                      print('Add Right Elevation Photo');
                    },
                  ),

                  // Rear Elevation Photo Section
                  PhotoSection(
                    icon: Icons.flip_camera_android_outlined,
                    title: 'Rear Elevation',
                    description: 'Photos of the rear view of the property.',
                    photoCountText: '0 / 5 photos',
                    onAddPhoto: () {
                      // Handle add photo for rear elevation
                      print('Add Rear Elevation Photo');
                    },
                  ),

                  // Roof Photo Section
                  PhotoSection(
                    icon: Icons.roofing_outlined,
                    title: 'Roof Photo',
                    description: 'Photos of the roof and roofing materials.',
                    photoCountText: '0 / 5 photos',
                    onAddPhoto: () {
                      // Handle add photo for roof
                      print('Add Roof Photo');
                    },
                  ),

                  // Additional Photos Section
                  PhotoSection(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'Additional Photos',
                    description: 'Any additional photos that may be relevant to the inspection.',
                    photoCountText: '0 / 10 photos',
                    onAddPhoto: () {
                      // Handle add photo for additional photos
                      print('Add Additional Photo');
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Center header_card(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
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
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.15),
                      colorScheme.secondary.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 20.0),

              // Headline
              Text(
                "Photo Collection",
                style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      fontSize: 18,
                    ) ??
                    TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12.0),

              // Description text
              Text(
                "Capture photos for each category, Tap 'Add Photo' to use your device camera or select from gallery.",
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.6,
                      fontSize: 14,
                    ) ??
                    TextStyle(
                      fontSize: 14.0,
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
