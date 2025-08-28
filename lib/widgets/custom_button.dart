import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  final bool outlined;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.icon,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    if (outlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isEnabled 
                ? (backgroundColor ?? theme.primaryColor)
                : Colors.grey[300]!,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _buildButtonContent(theme),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
            ? (backgroundColor ?? theme.primaryColor)
            : Colors.grey[300],
          foregroundColor: isEnabled 
            ? (textColor ?? Colors.white)
            : Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isEnabled ? 2 : 0,
        ),
        child: _buildButtonContent(theme),
      ),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            outlined ? (backgroundColor ?? theme.primaryColor) : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
