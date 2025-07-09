import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_questionaire_controller.dart';

class InspectionReportView extends StatelessWidget {
  const InspectionReportView({super.key});

  @override
  Widget build(BuildContext context) {
    // final InspectionPhotosController controller = Get.put(InspectionPhotosController());

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          child: Column(
            children: [
              // Header Card
              _buildHeaderCard(colorScheme, theme),
              
              // Complete and Save Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8.0),
                      _buildCompleteAndSaveSection(colorScheme, theme),
                      const Spacer(),
                      _buildCompleteButton(colorScheme, theme),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16.0),
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
                  Icons.done_all_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24.0),

              // Headline
              Text(
                "Finalize Inspection",
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
                "Save the completed inspection to your device. It will be uploaded automatically later.",
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

  Widget _buildCompleteAndSaveSection(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.save_alt_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12.0),
                Text(
                  "Complete and Save",
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        fontSize: 16,
                      ) ??
                      TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Description
            Text(
              "This will save all photos and answers to your device. You can view it on the \"Completed Inspections\" page.",
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                    fontSize: 14,
                  ) ??
                  TextStyle(
                    fontSize: 14.0,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF28A745), // Green color from the image
            const Color(0xFF20A841),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28A745).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle complete and save action
            _handleCompleteAndSave();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.save_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12.0),
                Text(
                  "Complete & Save Inspection",
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                      ) ??
                      const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCompleteAndSave() async {
    final controller = Get.find<QuestionnaireController>();
    final success = await controller.submitInspectionReport();
    if (success) {
      Get.snackbar(
        "Success",
        "Inspection report uploaded successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF28A745),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      // Optionally navigate to completed inspections page
      // Get.offNamed(AppRoutes.completedInspections);
    } else {
      Get.snackbar(
        "Error",
        controller.submissionError.value.isNotEmpty
            ? controller.submissionError.value
            : "Failed to upload inspection report.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}