import 'package:flutter/material.dart';

class RadioButtonWidget extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedValue;
  final bool isRequired;
  final bool isHorizontal;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool hasError;

  const RadioButtonWidget({
    Key? key,
    required this.label,
    required this.options,
    this.selectedValue,
    this.isRequired = false,
    this.isHorizontal = false,
    this.onChanged,
    this.validator,
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
          // Label
          RichText(
            text: TextSpan(
              text: label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              children: [
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

          const SizedBox(height: 8),

          // Radio buttons
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError
                    ? colorScheme.error
                    : colorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isHorizontal
                ? Row(
                    children: options.map((option) => _buildRadioOption(
                      context,
                      option,
                      isHorizontal: true,
                    )).toList(),
                  )
                : Column(
                    children: options.map((option) => _buildRadioOption(
                      context,
                      option,
                      isHorizontal: false,
                    )).toList(),
                  ),
          ),

          // Validation error
          if (hasError && validator != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                // Only call validator if it is a pure function (does not update state)
                (() {
                  try {
                    return validator!((selectedValue ?? '').toString()) ?? '';
                  } catch (_) {
                    return '';
                  }
                })(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildRadioOption(BuildContext context, String option, {required bool isHorizontal}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedValue == option;

    return SizedBox( // ✅ Fixed height for vertical layout
      height: 48, // Adjust as needed
      child: InkWell(
        onTap: () => onChanged?.call(option),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: options.indexOf(option) < options.length - 1 
                  ? colorScheme.outline.withOpacity(0.5) 
                  : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: option,
                groupValue: selectedValue,
                onChanged: onChanged,
                activeColor: colorScheme.primary,
              ),
              Text(
                option,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}