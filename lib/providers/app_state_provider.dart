import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_state_manager.dart';
import '../services/hive_session_service.dart';
import '../services/drift_chants_service.dart';
import '../services/secure_storage_service.dart';

/// Provider pour HiveSessionService
final hiveSessionServiceProvider = Provider<HiveSessionService>((ref) {
  return HiveSessionService();
});

/// Provider pour DriftChantsService
final driftChantsServiceProvider = Provider<DriftChantsService>((ref) {
  // Assurez-vous d'avoir initialisé votre database Drift
  return DriftChantsService(/* votre database */);
});

/// Provider pour SecureStorageService
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider pour Supabase Client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider pour AppStateManager
final appStateManagerProvider = Provider<AppStateManager>((ref) {
  return AppStateManager(
    hiveSession: ref.watch(hiveSessionServiceProvider),
    driftChants: ref.watch(driftChantsServiceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
    supabase: ref.watch(supabaseClientProvider),
  );
});

/// Provider pour l'état de connexion
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final appState = ref.watch(appStateManagerProvider);
  return await appState.isUserLoggedIn();
});

/// Provider pour l'utilisateur actuel
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final appState = ref.watch(appStateManagerProvider);
  return await appState.getCurrentUser();
});
