import 'package:flutter/material.dart';

/// Web platform bootstrap implementation (no dart:io or desktop APIs).
class PlatformBootstrap {
  static Future<void> initialize() async {}

  static Future<void> setDiscreetWindowTitle(bool discreet) async {}

  static Future<void> triggerMilestoneNotification({
    required String title,
    required String body,
  }) async {}

  static Widget wrapDesktopFrame({
    required Widget child,
    required bool discreetMode,
  }) => child;

  static Future<String?> saveEncryptedAtpFile(
    String content,
    String filename,
  ) async => null;
}
