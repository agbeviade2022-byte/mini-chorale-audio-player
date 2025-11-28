import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_auth_service.dart';
import '../services/hive_session_service.dart';
import '../services/encrypted_hive_service.dart';
import '../services/session_tracking_service.dart';
import '../services/secure_storage_service.dart';
import 'storage_providers.dart';

/// Provider pour EnhancedAuthService
final enhancedAuthServiceProvider = Provider<EnhancedAuthService>((ref) {
  final hiveSession = ref.watch(hiveSessionServiceProvider);
  
  return EnhancedAuthService(
    hiveSession,
    encryptedHive: EncryptedHiveService(),
    sessionTracking: SessionTrackingService(),
    secureStorage: SecureStorageService(),
  );
});
