import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIos) {
      return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                onAction?.call();
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAction?.call();
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      );
    }
  }
}
