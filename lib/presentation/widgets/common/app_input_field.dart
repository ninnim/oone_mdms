import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';

class AppInputField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool required;

  const AppInputField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.required = false,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label!,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              children: [
                if (widget.required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colorScheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.enabled
                ? colorScheme.surface
                : colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: AppSizes.fontSizeMedium,
            ),
            helperStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: AppSizes.fontSizeSmall,
            ),
            errorStyle: TextStyle(
              color: colorScheme.error,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ),
      ],
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool required;
  final bool enabled;

  const AppDropdownField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.required = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label!,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colorScheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: enabled
                ? colorScheme.surface
                : colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: AppSizes.fontSizeMedium,
            ),
          ),
        ),
      ],
    );
  }
}
