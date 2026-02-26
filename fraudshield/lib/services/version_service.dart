import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';
import '../widgets/update_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  static final VersionService instance = VersionService._internal();
  VersionService._internal();

  bool _hasChecked = false;

  Future<void> checkVersion(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final config = await ApiService.instance.getAppConfig();
      final minVersion = config['minVersion'] as String;
      final latestVersion = config['latestVersion'] as String;
      final updateUrl = config['updateUrl'];

      if (_isVersionLower(currentVersion, minVersion)) {
        // Force Update
        if (context.mounted) {
          await _showUpdateDialog(context, isForce: true, updateUrl: updateUrl);
        }
      } else if (_isVersionLower(currentVersion, latestVersion)) {
        // Optional Update
        if (context.mounted) {
          await _showUpdateDialog(context, isForce: false, updateUrl: updateUrl);
        }
      }
    } catch (e) {
      debugPrint('VersionService: Error checking version: $e');
    }
  }

  bool _isVersionLower(String current, String target) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> targetParts = target.split('.').map(int.parse).toList();

    for (int i = 0; i < targetParts.length; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (currentPart < targetParts[i]) return true;
      if (currentPart > targetParts[i]) return false;
    }
    return false;
  }

  Future<void> _showUpdateDialog(BuildContext context, {required bool isForce, dynamic updateUrl}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isForce,
      builder: (context) => UpdateDialog(
        isForce: isForce,
        onUpdate: () async {
          final url = Uri.parse(updateUrl != null ? updateUrl['android'] : '');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
