import 'recovery_storage.dart';
import 'web_storage.dart';

RecoveryStorage createPlatformStorage() => WebRecoveryStorage();
