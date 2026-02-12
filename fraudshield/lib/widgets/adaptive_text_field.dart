import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? placeholder;
  final int maxLines;

  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.placeholder,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isIos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.systemGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoTextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            placeholder: placeholder ?? label,
            maxLines: maxLines,
            padding: const EdgeInsets.all(16),
            prefix: prefixIcon != null 
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(prefixIcon, color: CupertinoColors.systemGrey),
                ) 
              : null,
            decoration: BoxDecoration(
              color: isDark 
                ? CupertinoColors.systemGrey6.darkColor 
                : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            style: TextStyle(
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      );
    } else {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // Modern "filled" look
          ),
          enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(16),
             borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
      );
    }
  }
}
