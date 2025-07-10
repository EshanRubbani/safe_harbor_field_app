import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_questionaire_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';
import 'package:safe_harbor_field_app/app/utils/form_section_widget.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_reports_controller.dart';

class InspectionQuestionnaireView extends StatelessWidget {
  const InspectionQuestionnaireView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Register the service before the controller
    final QuestionnaireService service = Get.find<QuestionnaireService>();
    final QuestionnaireController controller = Get.find<QuestionnaireController>();

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        
        // Save before popping
        await controller.saveOnNavigationBack();
        
        // Now pop the route
        Navigator.of(context).pop();
      },
      child: Scaffold(
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
              // Reactive save status indicator
              Obx(() {
                final hasUnsavedChanges = controller.hasUnsavedChanges;
                final isSavingManually = controller.isSavingManually;
                final reportsController = Get.find<InspectionReportsController>();
                final isAutoSaving = reportsController.isSaving.value;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!isSavingManually && !isAutoSaving) {
                              controller.saveFormDataManually();
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _getSaveIndicatorColor(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme).withOpacity(0.1),
                              border: Border.all(
                                color: _getSaveIndicatorColor(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildSaveIndicatorContent(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Header Card

              // Loading State
              Obx(() {
                if (controller.isLoading) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (controller.error.isNotEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading questions',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.error,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => service.loadQuestions(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

              
                // Form Content
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeaderCard(colorScheme, theme),

                          const SizedBox(height: 20),

                          // Dynamic Sections
                          ...controller.sections.map(
                            (section) => Obx(() => FormSectionWidget(
                                  title: section.title,
                                  icon: section.icon ?? Icons.quiz_outlined,
                                  isExpanded:
                                      controller.isSectionExpanded(section.id),
                                  onToggle: () =>
                                      controller.toggleSection(section.id),
                                  children: section.questions
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => Obx(() {
                                          final question = entry.value;
                                          final questionNumber = entry.key + 1;
                                          final hasError = controller
                                                  .fieldErrors[question.id] ==
                                              true;
                                          // Pass the numbered label to the widget
                                          return service.getWidgetForQuestion(
                                            question,
                                            labelPrefix: '$questionNumber. ',
                                            currentValue: controller
                                                .getFormValue(question.id)
                                                ?.toString(),
                                            onChanged: (value) =>
                                                controller.updateFormData(
                                                    question.id, value),
                                            validator: (value) =>
                                                controller.validateQuestion(
                                                    question, value),
                                            hasError: hasError, // Pass error state to widget
                                            viewOnly: controller.viewOnly.value,
                                          );
                                        }),
                                      )
                                      .toList(),
                                )),
                          ),

                          const SizedBox(
                              height: 100), // Space for floating button
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),

      // Floating Action Button with Progress
      floatingActionButton: Obx(() {
        if (controller.viewOnly.value) {
          return const SizedBox.shrink();
        }
        
        final answeredQuestions = controller.answeredQuestions;
        final totalQuestions = controller.totalQuestions;
        final answeredRequired = controller.answeredRequiredQuestions;
        final requiredQuestions = controller.requiredQuestions;
        final isFormValid = controller.isFormValid.value;
        
        // Always show the button with progress information
        return FloatingActionButton.extended(
          onPressed: () async {
            if (isFormValid) {
              await controller.saveFormDataManually();
              Get.toNamed(AppRoutes.inspection_report_finalize);
            } else {
              // Show progress information
              Get.snackbar(
                'Form Incomplete',
                'Please answer all required questions.\nRequired: $answeredRequired/$requiredQuestions\nTotal: $answeredQuestions/$totalQuestions',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            }
          },
          icon: Icon(
            isFormValid ? Icons.check_circle_outline_rounded : Icons.assignment_outlined,
          ),
          label: Text(
            isFormValid 
                ? 'Submit Questionnaire'
                : '$answeredQuestions/$totalQuestions Questions',
          ),
          backgroundColor: isFormValid ? colorScheme.primary : Colors.orange,
          foregroundColor: Colors.white,
        );
      }),
        ),

    
    );
  }

  // Helper method to get save indicator color
  Color _getSaveIndicatorColor(bool hasUnsavedChanges, bool isSavingManually, bool isAutoSaving, ColorScheme colorScheme) {
    if (isSavingManually || isAutoSaving) {
      return colorScheme.primary;
    } else if (hasUnsavedChanges) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Helper method to build save indicator content
  Widget _buildSaveIndicatorContent(bool hasUnsavedChanges, bool isSavingManually, bool isAutoSaving, ColorScheme colorScheme) {
    if (isSavingManually) {
      return Row(
        key: const ValueKey('saving_manually'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getSaveIndicatorColor(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Saving...',
            style: TextStyle(
              color: _getSaveIndicatorColor(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else if (isAutoSaving) {
      return Row(
        key: const ValueKey('auto_saving'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getSaveIndicatorColor(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Auto Saving...',
            style: TextStyle(
              color: _getSaveIndicatorColor(hasUnsavedChanges, isSavingManually, isAutoSaving, colorScheme),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else if (hasUnsavedChanges) {
      return Row(
        key: const ValueKey('unsaved'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Tap to Save',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else {
      return Row(
        key: const ValueKey('saved'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Saved',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    }
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
                  Icons.document_scanner_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24.0),

              // Headline
              Text(
                "Inspection Questionnaire",
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
                "Please answer all questions thoroughly. Your responses are saved as you go.",
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
