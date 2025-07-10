import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_questionaire_controller.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_reports_controller.dart';
import 'package:safe_harbor_field_app/app/models/inspection_report_model.dart';
import 'package:safe_harbor_field_app/app/controllers/auth_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';

class InspectionReportView extends StatelessWidget {
  const InspectionReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final InspectionReportsController reportsController = Get.find<InspectionReportsController>();
    final userId = Get.find<AuthController>().user?.uid ?? '';

    // Fetch cloud reports on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reportsController.fetchCloudReports();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Reports'),
        actions: [
          // Save status indicator in app bar
          Obx(() {
            final isSaving = reportsController.isSaving.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isSaving
                    ? Row(
                        key: const ValueKey('saving'),
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 6),
                          Text('Saving...', style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                        ],
                      )
                    : Row(
                        key: const ValueKey('saved'),
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text('Saved', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              reportsController.loadLocalReports();
              reportsController.fetchCloudReports();
            },
          ),
        ],
      ),
      body: Obx(() {
        // Combine local and cloud reports, deduplicate by id (cloud takes precedence)
        final local = reportsController.localReports;
        final cloud = reportsController.cloudReports;
        final Map<String, InspectionReportModel> allReportsMap = {
          for (var r in local) r.id: r,
          for (var r in cloud) r.id: r,
        };
        final allReports = allReportsMap.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (allReports.isEmpty) {
          return const Center(child: Text('No reports found.'));
        }

        return Column(
          children: [
            _buildHeaderCard(colorScheme, theme),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: allReports.length,
                itemBuilder: (context, idx) {
                  final report = allReports[idx];
                  String tag;
                  Color tagColor;

                  if (report.status == InspectionReportStatus.uploaded) {
                    tag = 'Synced';
                    tagColor = Colors.blue;
                  } else if (report.images.isNotEmpty && report.questionnaireResponses.isNotEmpty) {
                    tag = 'Completed';
                    tagColor = Colors.orange;
                  } else {
                    tag = 'In Progress';
                    tagColor = Colors.red;
                  }

                  return Card(
                    child: ListTile(
                      title: Text('Report ${report.id}'),
                      subtitle: Text('Updated: ${report.updatedAt}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        if (tag == 'In Progress' || tag == 'Completed') {
                          reportsController.resumeReport(report.id);
                          Get.toNamed(AppRoutes.inspection_photos);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
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
                  Icons.assessment_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24.0),

              // Headline
              Text(
                "Inspection Reports",
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
                "View and manage your inspection reports. In Progress reports can be resumed, Completed reports are ready for review.",
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