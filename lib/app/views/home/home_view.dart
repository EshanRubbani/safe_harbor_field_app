import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_harbor_field_app/app/controllers/auth_controller.dart';
import 'package:safe_harbor_field_app/app/controllers/inspection_reports_controller.dart';
import 'package:safe_harbor_field_app/app/routes/app_routes.dart';
import 'package:safe_harbor_field_app/app/utils/featured_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final _auth = Get.find<AuthController>();

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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.logout_rounded,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            _auth.logout();
                          },
                          color: colorScheme.onBackground,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Header Section
                  _buildHeaderSection(context, theme, colorScheme),

                  const SizedBox(height: 40),

                  // Features Section
                  _buildFeaturesSection(context, size),

                  const SizedBox(height: 40),

                  // CTA Button Section
                  _buildCTASection(context, theme, colorScheme),

                  const SizedBox(height: 30),

                  // Reports Section
                  _buildReportsSection(context, theme, colorScheme),

                  const SizedBox(height: 30),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.home_work_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(height: 24),

        // App Title
        Text(
          'Safe Harbor Field App',
          style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                fontSize: 28,
                letterSpacing: -0.5,
              ) ??
              TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Streamline residential underwriting inspections with our intuitive, state-of-the-art platform. Capture photos, complete questionnaires, and generate reports with unprecedented ease.',
            style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                  height: 1.6,
                  fontSize: 16,
                ) ??
                TextStyle(
                  fontSize: 16,
                  color: colorScheme.onBackground.withOpacity(0.8),
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, Size size) {
    return Column(
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Key Features',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onBackground,
                    ) ??
                TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
        ),

        // Features Carousel
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: 3,
            controller: PageController(viewportFraction: 0.88),
            itemBuilder: (context, index) {
              return _buildFeatureCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(int index) {
    switch (index) {
      case 0:
        return FeatureCard(
          icon: Icons.camera_outlined,
          headline: 'Efficient Photo Capture',
          text:
              'Easily take and categorize inspection photos. Supports all elevation views and additional details, ensuring nothing is missed.',
        );
      case 1:
        return FeatureCard(
          icon: Icons.checklist_rounded,
          headline: 'Comprehensive Questionnaire',
          text:
              'Complete detailed questionnaires with various question types, designed for quick and accurate data entry on the go.',
        );
      case 2:
        return FeatureCard(
          icon: Icons.document_scanner_rounded,
          headline: 'Instant PDF Reports',
          text:
              'Generate professional PDF reports instantly upon completion, ready for submission and review.',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCTASection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Secondary text
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Ready to transform your inspection workflow?',
            style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // CTA Button
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final reportsController = Get.put(InspectionReportsController());
              final userId = Get.find<AuthController>().user?.uid ?? '';
              // reportsController.exitViewOnlyMode();
              reportsController.startNewReport(userId);
              Get.toNamed(AppRoutes.inspection_photos);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start New Inspection',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );

      }



  Widget _buildReportsSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Secondary text
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'View Inspection Reports',
            style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // CTA Button
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Get.toNamed(AppRoutes.inspection_report);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Inspection Reports',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );

      }

      
}
