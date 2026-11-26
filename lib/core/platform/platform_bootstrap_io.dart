import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';

/// Native IO platform bootstrap for Windows, Android, iOS, macOS, and Linux.
class PlatformBootstrap {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsReady = false;
  static bool _windowReady = false;

  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await windowManager.ensureInitialized();
        const options = WindowOptions(
          size: Size(1240, 820),
          minimumSize: Size(420, 680),
          center: true,
          backgroundColor: AppColors.bgVoid,
          title: 'ATP Pomodoro',
          titleBarStyle: TitleBarStyle.hidden,
        );
        await windowManager.waitUntilReadyToShow(options, () async {
          await windowManager.show();
          await windowManager.focus();
        });
        _windowReady = true;
      } catch (e) {
        debugPrint('Window setup skipped: $e');
      }
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        windows: WindowsInitializationSettings(
          appName: 'ATP Pomodoro',
          appUserModelId: 'com.at.recovery.atppomodoro',
          guid: '9e2e479c-2f8a-4e2c-9a8d-7d5b20d1a001',
        ),
      );
      await _notifications.initialize(settings);
      _notificationsReady = true;
    } catch (e) {
      debugPrint('Notifications init skipped: $e');
    }
  }

  static Future<void> setDiscreetWindowTitle(bool discreet) async {
    if (!_windowReady) return;
    try {
      await windowManager.setTitle(
        discreet ? 'ATP Pomodoro' : 'AT Recovery RPG · ATP Pomodoro',
      );
    } catch (_) {}
  }

  static Future<void> triggerMilestoneNotification({
    required String title,
    required String body,
  }) async {
    if (!_notificationsReady) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'atp_sanctuary',
          'Sanctuary Milestones',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (_) {}
  }

  static Widget wrapDesktopFrame({
    required Widget child,
    required bool discreetMode,
  }) {
    if (!Platform.isWindows || !_windowReady) return child;
    return DragToResizeArea(
      child: Column(
        children: [
          Container(
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.bgVoid,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.accentEmerald,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DragToMoveArea(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        discreetMode
                            ? 'ATP Pomodoro'
                            : 'AT Recovery RPG · ATP Pomodoro',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 138,
                  height: 34,
                  child: WindowCaption(
                    brightness: Brightness.dark,
                    backgroundColor: AppColors.bgVoid,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  static Future<String?> saveEncryptedAtpFile(
    String content,
    String filename,
  ) async {
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final outFile = File(p.join(dir.path, filename));
      await outFile.writeAsString(content);
      return outFile.path;
    } catch (_) {
      return null;
    }
  }
}
