import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String text;
  final Color? iconColor;
  final Color? headlineColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double? iconSize;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.headline,
    required this.text,
    this.iconColor,
    this.headlineColor,
    this.textColor,
    this.backgroundColor,
    this.iconSize = 48.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor ?? colorScheme.surface,
                backgroundColor?.withOpacity(0.8) ?? colorScheme.surface.withOpacity(0.95),
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
                  icon,
                  size: iconSize,
                  color: iconColor ?? colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 20.0),
              
              // Headline
              Text(
                headline,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: headlineColor ?? colorScheme.onSurface,
                  fontSize: 18,
                ) ?? TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: headlineColor ?? colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12.0),
              
              // Description text
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor ?? colorScheme.onSurface.withOpacity(0.7),
                  height: 1.6,
                  fontSize: 14,
                ) ?? TextStyle(
                  fontSize: 14.0,
                  color: textColor ?? colorScheme.onSurface.withOpacity(0.7),
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