import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DateInputWidget extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final bool isRequired;
  final void Function(DateTime?)? onChanged;
  final String? Function(DateTime?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool hasError;

  const DateInputWidget({
    Key? key,
    required this.label,
    this.initialDate,
    this.isRequired = false,
    this.onChanged,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.hasError = false,
  }) : super(key: key);

  @override
  State<DateInputWidget> createState() => _DateInputWidgetState();
}

class _DateInputWidgetState extends State<DateInputWidget> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: colorScheme,
            dialogBackgroundColor: colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      widget.onChanged?.call(picked);
    }
  }

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
                  TextSpan(text: widget.label),
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
          ),

          // Date Input Field
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: widget.hasError
                      ? colorScheme.error
                      : colorScheme.outline.withOpacity(0.5),
                  width: 1.5,
                ),
                color: colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null
                        ? "${selectedDate!.toLocal().toIso8601String().split('T').first}"
                        : 'Select ${widget.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (widget.hasError && widget.validator != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.validator!(selectedDate) ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}