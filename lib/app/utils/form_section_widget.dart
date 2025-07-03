import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormSectionWidget extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Color? backgroundColor;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const FormSectionWidget({
    Key? key,
    required this.title,
    this.icon,
    required this.children,
    this.backgroundColor,
    this.isExpanded = true,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: backgroundColor ?? colorScheme.surface,
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.05),
                        colorScheme.secondary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      if (icon != null)
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),

                      if (icon != null) const SizedBox(width: 16.0),

                      // Title
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      // Expand/Collapse Arrow (if onToggle is provided)
                      if (onToggle != null)
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Section Content
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}