import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ClipboardMonitorService with WidgetsBindingObserver {
  static final ClipboardMonitorService instance =
      ClipboardMonitorService._internal();
  factory ClipboardMonitorService() => instance;
  ClipboardMonitorService._internal();

  final _malaysiaPhoneRegex = RegExp(r'^(\+60|0)(3|[1-9][0-9])\s?\d{7,8}$');
  String? _lastCopied;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    if (text != null &&
        text != _lastCopied &&
        _malaysiaPhoneRegex.hasMatch(text)) {
      _lastCopied = text;
      _showSuggestion(text);
    }
  }

  void _showSuggestion(String number) {
    // In a real app, we might use a global key or a context-aware service to show a snackbar/dialog
    debugPrint('FraudShield: Suggesting check for number $number');
  }
}
