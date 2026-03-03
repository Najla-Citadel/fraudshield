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
  final bool? filled;
  final Color? fillColor;
  final Color? textColor;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
<<<<<<< HEAD
=======
  final IconData? suffixIcon;
>>>>>>> dev-ui2

  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.placeholder,
    this.maxLines = 1,
    this.filled,
    this.fillColor,
    this.textColor,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
<<<<<<< HEAD
=======
    this.suffixIcon,
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                color: isDark ? CupertinoColors.white : CupertinoColors.systemGrey,
=======
                color:
                    isDark ? CupertinoColors.white : CupertinoColors.systemGrey,
>>>>>>> dev-ui2
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
            autofocus: autofocus,
            readOnly: readOnly,
            enabled: enabled,
            padding: const EdgeInsets.all(16),
<<<<<<< HEAD
            prefix: prefixIcon != null 
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(prefixIcon, color: CupertinoColors.systemGrey),
                ) 
              : null,
            decoration: BoxDecoration(
              color: fillColor ?? (isDark 
                ? CupertinoColors.systemGrey6.darkColor 
                : CupertinoColors.systemGrey6),
              borderRadius: BorderRadius.circular(12),
            ),
            style: TextStyle(
              color: textColor ?? (isDark ? CupertinoColors.white : CupertinoColors.black),
=======
            prefix: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(prefixIcon, color: CupertinoColors.systemGrey),
                  )
                : null,
            suffix: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(suffixIcon, color: CupertinoColors.systemGrey),
                  )
                : null,
            decoration: BoxDecoration(
              color: fillColor ??
                  (isDark
                      ? CupertinoColors.systemGrey6.darkColor
                      : CupertinoColors.systemGrey6),
              borderRadius: BorderRadius.circular(12),
            ),
            style: TextStyle(
              color: textColor ??
                  (isDark ? CupertinoColors.white : CupertinoColors.black),
>>>>>>> dev-ui2
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
        autofocus: autofocus,
        readOnly: readOnly,
        enabled: enabled,
<<<<<<< HEAD
        style: TextStyle(color: textColor ?? (isDark ? Colors.white : Colors.black)),
=======
        style: TextStyle(
            color: textColor ?? (isDark ? Colors.white : Colors.black)),
>>>>>>> dev-ui2
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
<<<<<<< HEAD
=======
          suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
>>>>>>> dev-ui2
          filled: filled ?? true,
          fillColor: fillColor ?? (isDark ? Colors.grey[900] : Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // Modern "filled" look
          ),
          enabledBorder: OutlineInputBorder(
<<<<<<< HEAD
             borderRadius: BorderRadius.circular(16),
             borderSide: BorderSide.none,
=======
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
>>>>>>> dev-ui2
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
