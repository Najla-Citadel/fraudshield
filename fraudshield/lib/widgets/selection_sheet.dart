import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../design_system/components/app_divider.dart';

class SelectionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required String Function(T) labelBuilder,
  }) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIos) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          actions: options.map((option) {
            return CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, option),
              child: Text(labelBuilder(option)),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => AppDivider(),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return ListTile(
                      title: Text(
                        labelBuilder(option),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () => Navigator.pop(context, option),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    }
  }
}
