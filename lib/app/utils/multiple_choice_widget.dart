import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedValue;
  final bool isRequired;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool isHorizontal;
  final bool hasError;

  const MultipleChoiceWidget({
    Key? key,
    required this.label,
    required this.options,
    this.selectedValue,
    this.isRequired = false,
    this.onChanged,
    this.validator,
    this.isHorizontal = true,
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
            padding: const EdgeInsets.only(bottom: 12.0),
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

          // Options Container
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: hasError
                    ? colorScheme.error
                    : colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
              color: colorScheme.surface,
            ),
            child: isHorizontal
                ? _buildHorizontalOptions(theme, colorScheme)
                : _buildVerticalOptions(theme, colorScheme),
          ),
          if (hasError && validator != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                validator!((selectedValue ?? '').toString()) ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalOptions(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: options.asMap().entries.map((entry) {
        final option = entry.value;
        final isSelected = selectedValue == option;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: entry.key < options.length - 1 ? 12.0 : 0,
            ),
            child: _buildOptionButton(option, isSelected, theme, colorScheme),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerticalOptions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildOptionButton(option, isSelected, theme, colorScheme),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton(
    String option,
    bool isSelected,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => onChanged?.call(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
            Text(
              option,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}