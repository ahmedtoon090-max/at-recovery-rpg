import 'recovery_storage.dart';
import 'sqlite_storage.dart';

RecoveryStorage createPlatformStorage() => SqliteRecoveryStorage();
