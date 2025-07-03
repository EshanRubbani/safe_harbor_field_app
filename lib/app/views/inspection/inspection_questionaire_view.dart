import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_questionaire_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/services/questionaire_service.dart';
import 'package:safe_harbor_field_app/app/utils/form_section_widget.dart';

class InspectionQuestionnaireView extends StatelessWidget {
  const InspectionQuestionnaireView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Register the service before the controller
    final QuestionnaireService service = Get.put(QuestionnaireService());
    final QuestionnaireController controller =
        Get.put(QuestionnaireController());

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

                if (controller.sections.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No questions available',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Initialize default questions to get started',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: controller.initializeDefaultQuestions,
                            child: const Text('Initialize Questions'),
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

      // Floating Action Button
      floatingActionButton: Obx(() => AnimatedScale(
            scale: controller.isFormValid.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: controller.isFormValid.value
                ? FloatingActionButton.extended(
                    onPressed: () {
                      if (controller.submitForm()) {
                        // Navigate to next screen or perform action
                        Get.toNamed(AppRoutes.inspection_report);
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Submit Questionnaire'),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  )
                : const SizedBox.shrink(),
          )),

      // App Bar with actions
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // // Initialize Questions Button (temporary)
          // Obx(() {
          //   if (controller.sections.isEmpty && !controller.isLoading) {
          //     return TextButton.icon(
          //       onPressed: controller.initializeDefaultQuestions,
          //       icon:
          //           Icon(Icons.add_circle_outline, color: colorScheme.primary),
          //       label: Text('Init Questions',
          //           style: TextStyle(color: colorScheme.primary)),
          //     );
          //   }
          //   return const SizedBox.shrink();
          // }),

          // Save Draft Button
          TextButton.icon(
            onPressed: controller.saveDraft,
            icon: Icon(Icons.save_rounded, color: colorScheme.primary),
            label: Text('Save Draft',
                style: TextStyle(color: colorScheme.primary)),
          ),

          // // Refresh Button
          // IconButton(
          //   onPressed: () => service.loadQuestions(),
          //   icon: Icon(Icons.refresh, color: colorScheme.primary),
          //   tooltip: 'Refresh Questions',
          // ),
        ],
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
