import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TextInputWidget extends StatelessWidget {
  final String label;
  final String? initialValue;
  final String? hintText;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final bool hasError;

  const TextInputWidget({
    Key? key,
    required this.label,
    this.initialValue,
    this.hintText,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.controller,
    this.hasError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with required indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                children: [
                  TextSpan(text: label),
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Text Input Field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: hasError
                    ? colorScheme.error
                    : colorScheme.outline.withOpacity(0.5),
                width: 1.5,
              ),
              color: colorScheme.surface,
            ),
            child: TextFormField(
              controller: controller,
              initialValue: controller == null ? initialValue : null,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? 'Enter $label',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                ),
              validator: validator,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}