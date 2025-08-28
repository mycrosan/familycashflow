import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final bool enabled;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    Key? key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      onTap: onTap,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[500]!, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          color: enabled ? Colors.grey[700] : Colors.grey[500],
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
        ),
      ),
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey[600],
      ),
    );
  }
}
