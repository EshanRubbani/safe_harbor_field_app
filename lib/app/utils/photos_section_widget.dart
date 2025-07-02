import 'package:flutter/material.dart';

class PhotoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String photoCountText;
  final bool isRequired;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onAddPhoto;
  final List<String>? photos; // For future use when photos are added

  const PhotoSection({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.photoCountText,
    this.isRequired = false,
    this.hasError = false,
    this.errorMessage,
    this.onAddPhoto,
    this.photos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasError 
            ? Colors.red.withOpacity(0.3)
            : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  icon,
                  color: hasError 
                    ? Colors.red 
                    : colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasError 
                        ? Colors.red 
                        : colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  photoCountText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Photo Upload Area
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddPhoto,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Error Message
            if (hasError && errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}