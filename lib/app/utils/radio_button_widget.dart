import 'package:flutter/material.dart';

class RadioButtonWidget extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? selectedValue;
  final bool isRequired;
  final bool isHorizontal;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool hasError;
  final bool enabled;
  final bool hasOther;
  final String? otherValue;
  final Function(String)? onOtherChanged;

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
    this.enabled = true,
    this.hasOther = false,
    this.otherValue,
    this.onOtherChanged,
  }) : super(key: key);

  @override
  State<RadioButtonWidget> createState() => _RadioButtonWidgetState();
}

class _RadioButtonWidgetState extends State<RadioButtonWidget> {
  late TextEditingController _otherController;
  late FocusNode _otherFocusNode;
  String? _previousOtherValue;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: widget.otherValue);
    _otherFocusNode = FocusNode();
    _previousOtherValue = widget.otherValue;
  }

  @override
  void didUpdateWidget(RadioButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update the controller if the value actually changed from outside
    if (widget.otherValue != _previousOtherValue && 
        widget.otherValue != _otherController.text) {
      _otherController.text = widget.otherValue ?? '';
      _previousOtherValue = widget.otherValue;
    }
    
    // Maintain focus when the widget rebuilds if "Other" is still selected
    if (widget.selectedValue == 'Other' && oldWidget.selectedValue != 'Other') {
      // Focus the text field when "Other" is newly selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _otherFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    _otherFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create the effective options list
    // Only add "Other" if hasOther is true AND "Other" is not already in the options
    final effectiveOptions = List<String>.from(widget.options);
    if (widget.hasOther && !effectiveOptions.contains('Other')) {
      effectiveOptions.add('Other');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          RichText(
            text: TextSpan(
              text: widget.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              children: [
                if (widget.isRequired)
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
                color: widget.hasError
                    ? colorScheme.error
                    : colorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.isHorizontal
                ? Row(
                    children: effectiveOptions.map((option) => _buildRadioOption(
                      context,
                      option,
                      isHorizontal: true,
                    )).toList(),
                  )
                : Column(
                    children: effectiveOptions.map((option) => _buildRadioOption(
                      context,
                      option,
                      isHorizontal: false,
                    )).toList(),
                  ),
          ),

          // Other text field
          if (widget.hasOther && widget.selectedValue == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextFormField(
                key: ValueKey('other_field_${widget.label}'),
                controller: _otherController,
                focusNode: _otherFocusNode,
                enabled: widget.enabled,
                onChanged: (value) {
                  // Prevent unnecessary rebuilds by checking if value actually changed
                  if (value != _previousOtherValue) {
                    _previousOtherValue = value;
                    widget.onOtherChanged?.call(value);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Please specify',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),

          // Validation error
          if (widget.hasError && widget.validator != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                // Only call validator if it is a pure function (does not update state)
                (() {
                  try {
                    return widget.validator!((widget.selectedValue ?? '').toString()) ?? '';
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
    final isSelected = widget.selectedValue == option;

    return SizedBox( // ✅ Fixed height for vertical layout
      height: 48, // Adjust as needed
      child: InkWell(
        onTap: widget.enabled ? () => widget.onChanged?.call(option) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.options.indexOf(option) < widget.options.length - 1 
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
                groupValue: widget.selectedValue,
                onChanged: widget.enabled ? widget.onChanged : null,
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