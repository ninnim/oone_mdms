import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';

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
  final List<TextInputFormatter>? inputFormatters;

  // New alignment and spacing parameters
  final bool showErrorSpace; // Whether to reserve space for error messages
  final bool isDense; // Whether to use dense padding
  final double? customHeight; // Custom height override
  final TextAlignVertical? textAlignVertical; // Text vertical alignment
  final EdgeInsets? contentPadding; // Custom content padding

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
    this.inputFormatters,
    // New parameters with sensible defaults
    this.showErrorSpace = true,
    this.isDense = false,
    this.customHeight,
    this.textAlignVertical,
    this.contentPadding,
  });

  // Convenience constructor for search fields with perfect center alignment
  const AppInputField.search({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  }) : label = null,
       helperText = null,
       errorText = null,
       validator = null,
       onTap = null,
       obscureText = false,
       readOnly = false,
       keyboardType = null,
       maxLines = 1,
       minLines = null,
       required = false,
       inputFormatters = null,
       showErrorSpace = false, // No error space for search
       isDense = true, // Compact for toolbars
       customHeight = 36.0, // Fixed height for consistency
       textAlignVertical = TextAlignVertical.center,
       contentPadding = const EdgeInsets.symmetric(
         horizontal: 16.0,
         vertical: 0.0,
       );

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _errorText = widget.errorText;
  }

  @override
  void didUpdateWidget(AppInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  String? _customValidator(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      // Update error state immediately for better UX
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _errorText != error) {
          setState(() {
            _errorText = error;
          });
        }
      });
      return null; // Always return null to prevent built-in error display
    }
    return null;
  }

  void _onTextChanged(String value) {
    // Call user's onChanged callback
    widget.onChanged?.call(value);

    // Auto-validate to clear error when user types valid input
    if (_errorText != null && widget.validator != null) {
      final newError = widget.validator!(value);
      if (newError != _errorText) {
        setState(() {
          _errorText = newError;
        });
      }
    }
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
        // Input field with dynamic height
        SizedBox(
          height:
              widget.customHeight ??
              (widget.maxLines != null && widget.maxLines! > 1
                  ? null // Allow multi-line fields to be flexible
                  : AppSizes.inputHeight),
          child: TextFormField(
            controller: widget.controller,
            style: TextStyle(
              fontSize: AppSizes
                  .fontSizeMedium, // Use medium font size for better readability
              color: colorScheme.onSurface,
              height: 1.4, // Better line height for vertical centering
            ),
            textAlignVertical:
                widget.textAlignVertical ?? TextAlignVertical.center,
            focusNode: _focusNode,
            validator: _customValidator,
            onChanged: _onTextChanged,
            onTap: widget.onTap,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            inputFormatters: widget.inputFormatters,
            decoration: InputDecoration(
              hintText: widget.hintText,
              helperText: widget.helperText,
              // Remove errorText from here to prevent resizing
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: widget.enabled
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                borderSide: BorderSide(
                  color: _errorText != null
                      ? colorScheme.error
                      : context.borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                borderSide: BorderSide(
                  color: _errorText != null
                      ? colorScheme.error
                      : context.borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                borderSide: BorderSide(
                  color: _errorText != null
                      ? colorScheme.error
                      : colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                borderSide: BorderSide(color: colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                borderSide: BorderSide(color: colorScheme.error, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                borderSide: BorderSide(color: context.borderColor),
              ),
              contentPadding:
                  widget.contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing16,
                    vertical: widget.isDense
                        ? AppSizes.spacing8
                        : AppSizes.spacing12,
                  ),
              isDense: widget.isDense,
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
        ),
        // Conditional error message space
        if (widget.showErrorSpace)
          SizedBox(
            height: 20, // Fixed height for error message area
            child: _errorText != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 0, // Align to the left edge of the field
                      top: AppSizes.spacing4,
                    ),
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: AppSizes.fontSizeSmall,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          )
        else if (_errorText != null)
          // Show error immediately below field without reserved space
          Padding(
            padding: const EdgeInsets.only(left: 0, top: AppSizes.spacing4),
            child: Text(
              _errorText!,
              style: TextStyle(
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
                : colorScheme.surfaceContainerHighest,
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
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ),
      ],
    );
  }
}
