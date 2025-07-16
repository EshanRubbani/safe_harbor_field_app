import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_questionaire_controller.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_reports_controller.dart';
import 'package:safe_harbor_field_app/app/models/inspection_report_model.dart';
import 'package:safe_harbor_field_app/app/controllers/auth_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/services/pdf_generation_service.dart';

class InspectionReportView extends StatelessWidget {
  const InspectionReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final InspectionReportsController reportsController =
        Get.find<InspectionReportsController>();
    final userId = Get.find<AuthController>().user?.uid ?? '';

    // Fetch cloud reports on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reportsController.fetchCloudReports();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final isLoading = reportsController.isLoadingCloudReports.value;
            return Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        reportsController.loadLocalReports();
                        reportsController.fetchCloudReports();
                      },
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  isLoading ? 'Refreshing...' : 'Refresh',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            );
          }),
        ],
      ),
      body: Container(
        child: Obx(() {
          // Combine local and cloud reports, deduplicate by id (cloud takes precedence)
          final local = reportsController.localReports;
          final cloud = reportsController.cloudReports;
          final Map<String, InspectionReportModel> allReportsMap = {
            for (var r in local) r.id: r,
            for (var r in cloud) r.id: r,
          };
          final allReports = allReportsMap.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return ListView.builder(
            padding: const EdgeInsets.only(top: 0, bottom: 16),
            itemCount: allReports.isEmpty
                ? 2
                : allReports.length +
                    2, // 0: header, 1: subtitle, rest: reports
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header card
                return _buildHeaderCard(colorScheme, theme);
              }
              if (index == 1) {
                // Subtitle header
                return const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'View synced and pending reports.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                );
              }
              final reportIndex = index - 2;
              if (allReports.isEmpty) {
                // Only show empty state after header and subtitle
                if (index == 2) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'View synced and pending reports.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }
              if (reportIndex >= allReports.length)
                return const SizedBox.shrink();
              final report = allReports[reportIndex];
              // Get the total questions from the questionnaire controller
              final questionnaireController =
                  Get.find<QuestionnaireController>();
              final totalQuestions = questionnaireController.totalQuestions;
              final completionTag =
                  report.completionTag(totalQuestions: totalQuestions);
              final completionStats =
                  report.completionStats(totalQuestions: totalQuestions);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, reportIndex == allReports.length - 1 ? 20 : 0),
                child: _buildReportCard(
                  report: report,
                  completionTag: completionTag,
                  completionStats: completionStats,
                  reportsController: reportsController,
                ),
              );
            },
          );
        }),
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

  Widget _buildReportCard({
    required InspectionReportModel report,
    required String completionTag,
    required Map<String, dynamic> completionStats,
    required InspectionReportsController reportsController,
  }) {
    // Extract address and policy info from questionnaire responses
    final responses = report.questionnaireResponses;
    final address = _extractAddress(responses, report.id);
    final policyNumber = _extractPolicyNumber(responses);

    Color tagColor;
    Color tagBackgroundColor;
    IconData tagIcon;

    switch (completionTag) {
      case 'Synced':
        tagColor = const Color(0xFF059669);
        tagBackgroundColor = const Color(0xFFD1FAE5);
        tagIcon = Icons.cloud_done_rounded;
        break;
      case 'Completed':
      case 'Pending':
        tagColor = const Color(0xFFD97706);
        tagBackgroundColor = const Color(0xFFFEF3C7);
        tagIcon = Icons.schedule_rounded;
        break;
      default:
        tagColor = const Color(0xFFDC2626);
        tagBackgroundColor = const Color(0xFFFEE2E2);
        tagIcon = Icons.warning_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with address and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.policy_rounded,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Policy #: $policyNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDateLabel(completionTag, report.updatedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tagIcon,
                        size: 12,
                        color: tagColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        completionTag == 'Completed'
                            ? 'Pending'
                            : completionTag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: tagColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                report: report,
                completionTag: completionTag,
                reportsController: reportsController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required InspectionReportModel report,
    required String completionTag,
    required InspectionReportsController reportsController,
  }) {
    if (completionTag == 'Synced') {
      return ElevatedButton.icon(
        onPressed: () async {
          // Generate PDF for the corresponding report using dynamic PDF generation
          final reportsController = Get.find<InspectionReportsController>();

          // Show loading dialog
          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Generating PDF...',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            barrierDismissible: false,
          );

          try {
            final pdfPath =
                await reportsController.generateDynamicPDF(report.id);
            Get.back(); // Close loading dialog

            if (pdfPath != null) {
              Get.snackbar(
                'PDF Generated',
                'PDF saved to downloads successfully!',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );

              // Try to open the PDF
              try {
                final result = await OpenFile.open(pdfPath);
                if (result.type != ResultType.done) {
                  Get.snackbar(
                    'PDF Ready',
                    'PDF saved to app documents. You can find it in your file manager.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                }
              } catch (e) {
                print('Error opening PDF: $e');
              }
            } else {
              Get.snackbar(
                'Error',
                'Failed to generate PDF. Please try again.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } catch (e) {
            Get.back(); // Close loading dialog
            Get.snackbar(
              'Error',
              'An error occurred while generating PDF: ${e.toString()}',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
        label: const Text(
          'Generate PDF',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF374151),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      );
    } else if (completionTag == 'Completed') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await reportsController.uploadReport(report.id);
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Report uploaded successfully!',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              },
              icon: const Icon(Icons.cloud_upload_rounded, size: 16),
              label: const Text(
                'Upload Now',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _showDeleteConfirmation(report.id, reportsController);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
    } else {
      // In Progress
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                reportsController.resumeReport(report.id);
                Get.toNamed(AppRoutes.inspection_photos);
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Continue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _showDeleteConfirmation(report.id, reportsController);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
    }
  }

  void _showDeleteConfirmation(
      String reportId, InspectionReportsController reportsController) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await reportsController.deleteInProgressReport(reportId);
              Get.snackbar(
                'Deleted',
                'Report has been deleted successfully',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _extractAddress(Map<String, dynamic> responses, String reportId) {
    // Extract Insured Street Address, State, and Zip Code from questionnaire
    // Support both enhanced structure and legacy structure
    final streetAddressFields = [
      'insured_street_address',
      'street_address',
      'property_address',
      'insured_address',
      'address',
      'street'
    ];

    final stateFields = ['insured_state', 'state', 'property_state'];

    final zipFields = [
      'insured_zip_code',
      'zip_code',
      'postal_code',
      'insured_zip',
      'zip'
    ];

    String? streetAddress;
    String? state;
    String? zipCode;

    // Helper function to extract value from enhanced or legacy structure
    String? extractValue(Map<String, dynamic> data, List<String> fieldKeys) {
      for (final field in fieldKeys) {
        // Check enhanced structure first
        final enhancedValue = data[field];
        if (enhancedValue != null) {
          if (enhancedValue is Map<String, dynamic> &&
              enhancedValue.containsKey('value')) {
            final value = enhancedValue['value'];
            if (value != null && value.toString().trim().isNotEmpty) {
              return value.toString().trim();
            }
          } else if (enhancedValue.toString().trim().isNotEmpty) {
            // Legacy structure or direct value
            return enhancedValue.toString().trim();
          }
        }
      }

      // Also search by question text patterns for additional fallback
      for (final entry in data.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        // Check if this looks like an address field based on key patterns
        for (final fieldKey in fieldKeys) {
          if (key.contains(fieldKey.replaceAll('_', ' ')) ||
              key.contains(fieldKey)) {
            if (value is Map<String, dynamic> && value.containsKey('value')) {
              final extractedValue = value['value'];
              if (extractedValue != null &&
                  extractedValue.toString().trim().isNotEmpty) {
                return extractedValue.toString().trim();
              }
            } else if (value != null && value.toString().trim().isNotEmpty) {
              return value.toString().trim();
            }
          }
        }
      }

      return null;
    }

    // Extract address components
    streetAddress = extractValue(responses, streetAddressFields);
    state = extractValue(responses, stateFields);
    zipCode = extractValue(responses, zipFields);

    // Build address string
    final addressParts = <String>[];
    if (streetAddress != null) addressParts.add(streetAddress);
    if (state != null) addressParts.add(state);
    if (zipCode != null) addressParts.add(zipCode);

    // If we have address components, join them
    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    // Fallback to report ID if no address found
    return 'Report ${reportId.split('_').last}';
  }

  String _extractPolicyNumber(Map<String, dynamic> responses) {
    final policyFields = [
      'policy_number',
      'pol_number',
      'policy_no',
      'policy_num',
      'policy'
    ];

    // Helper function to extract value from enhanced or legacy structure
    String? extractValue(Map<String, dynamic> data, List<String> fieldKeys) {
      for (final field in fieldKeys) {
        // Check enhanced structure first
        final enhancedValue = data[field];
        if (enhancedValue != null) {
          if (enhancedValue is Map<String, dynamic> &&
              enhancedValue.containsKey('value')) {
            final value = enhancedValue['value'];
            if (value != null && value.toString().trim().isNotEmpty) {
              return value.toString().trim();
            }
          } else if (enhancedValue.toString().trim().isNotEmpty) {
            // Legacy structure or direct value
            return enhancedValue.toString().trim();
          }
        }
      }

      // Also search by question text patterns for additional fallback
      for (final entry in data.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        // Check if this looks like a policy field based on key patterns
        for (final fieldKey in fieldKeys) {
          if (key.contains(fieldKey.replaceAll('_', ' ')) ||
              key.contains(fieldKey)) {
            if (value is Map<String, dynamic> && value.containsKey('value')) {
              final extractedValue = value['value'];
              if (extractedValue != null &&
                  extractedValue.toString().trim().isNotEmpty) {
                return extractedValue.toString().trim();
              }
            } else if (value != null && value.toString().trim().isNotEmpty) {
              return value.toString().trim();
            }
          }
        }
      }

      return null;
    }

    final policyNumber = extractValue(responses, policyFields);
    return policyNumber ?? 'N/A';
  }

  String _getDateLabel(String completionTag, DateTime date) {
    if (completionTag == 'In Progress') {
      return 'Last updated: ${_formatDate(date)}';
    } else {
      return 'Completed: ${_formatDate(date)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
