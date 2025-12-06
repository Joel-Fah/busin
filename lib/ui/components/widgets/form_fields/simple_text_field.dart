import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../utils/constants.dart';

class SimpleTextFormField extends StatelessWidget {
  const SimpleTextFormField({
    super.key,
    required this.controller,
    this.scrollController,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.suffix,
    this.enabled,
    this.minLines,
    this.maxLines,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    required this.label,
    this.readOnly,
  });

  final TextEditingController controller;
  final ScrollController? scrollController;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String hintText;
  final Widget label;
  final Widget? suffixIcon;
  final Function(String value)? onChanged;
  final String? Function(String? value)? validator;
  final Widget? prefixIcon, suffix;
  final bool? enabled, readOnly;
  final int? minLines, maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: seedPalette.shade50.withValues(alpha: 0.1),
      child: TextFormField(
        controller: controller,
        scrollController: scrollController,
        enabled: enabled,
        readOnly: readOnly ?? false,
        focusNode: focusNode,
        style: AppTextStyles.body,
        keyboardType: keyboardType ?? TextInputType.text,
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        inputFormatters: inputFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        minLines: minLines,
        maxLines: maxLines,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,
          ),
          label: label,
          labelStyle: AppTextStyles.body.copyWith(color: seedColor),
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(color: greyColor),
          errorMaxLines: 5,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          suffixIconColor: seedColor,
          suffix: suffix,
          border: AppInputBorders.border,
          focusedBorder: AppInputBorders.focusedBorder,
          errorBorder: AppInputBorders.errorBorder,
          focusedErrorBorder: AppInputBorders.focusedErrorBorder,
          enabledBorder: AppInputBorders.enabledBorder,
          disabledBorder: AppInputBorders.disabledBorder,
        ),
        onChanged: onChanged,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }
}
