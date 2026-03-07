import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  final Map<T, Widget> children;
  final T groupValue;
  final ValueChanged<T> onValueChanged;

  const AdaptiveSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIos) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          children: children,
          groupValue: groupValue,
          onValueChanged: (value) {
            if (value != null) onValueChanged(value);
          },
          backgroundColor: CupertinoColors.tertiarySystemFill,
          thumbColor: CupertinoColors.white,
        ),
      );
    } else {
      return SegmentedButton<T>(
        segments: children.entries.map((entry) {
          return ButtonSegment<T>(
            value: entry.key,
            label: entry.value,
          );
        }).toList(),
        selected: {groupValue},
        onSelectionChanged: (Set<T> newSelection) {
          onValueChanged(newSelection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radii.sm)),
          ),
        ),
        showSelectedIcon: false, // Cleaner look
      );
    }
  }
}
