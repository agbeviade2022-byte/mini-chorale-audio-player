import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/services/enhanced_auth_service.dart';
import 'package:mini_chorale_audio_player/services/hive_session_service.dart';
import 'package:mini_chorale_audio_player/services/encrypted_hive_service.dart';
import 'package:mini_chorale_audio_player/services/session_tracking_service.dart';
import 'package:mini_chorale_audio_player/services/secure_storage_service.dart';
import 'package:mini_chorale_audio_player/providers/storage_providers.dart';
import 'package:mini_chorale_audio_player/models/user.dart';
import 'package:mini_chorale_audio_player/providers/permissions_provider_riverpod.dart';

// Provider du service d'authentification amélioré avec sécurité niveau Spotify
final authServiceProvider = Provider<EnhancedAuthService>((ref) {
  final hiveSession = ref.watch(hiveSessionServiceProvider);
  
  // Initialiser les services de sécurité
  final encryptedHive = EncryptedHiveService();
  final sessionTracking = SessionTrackingService();
  final secureStorage = SecureStorageService();
  
  return EnhancedAuthService(
    hiveSession,
    encryptedHive: encryptedHive,
    sessionTracking: sessionTracking,
    secureStorage: secureStorage,
  );
});

// Provider de l'état d'authentification
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider de l'utilisateur actuel
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// Provider du profil utilisateur
final userProfileProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final hiveSession = ref.watch(hiveSessionServiceProvider);
  
  // 1. Essayer de récupérer depuis Hive (plus rapide)
  final session = hiveSession.getSession();
  if (session != null && session.isValid) {
    print('✅ Profil récupéré depuis Hive: ${session.fullName}');
    return AppUser(
      id: '', // Pas stocké dans Hive
      userId: session.userId,
      fullName: session.fullName,
      role: session.role,
      email: session.email,
      createdAt: session.createdAt,
    );
  }
  
  // 2. Sinon, récupérer depuis Supabase
  final currentUser = authService.currentUser;
  if (currentUser == null) return null;

  try {
    final profileData = await authService.getUserProfile();
    if (profileData == null) return null;
    print('✅ Profil récupéré depuis Supabase');
    return AppUser.fromMap(profileData);
  } catch (e) {
    print('❌ Erreur récupération profil: $e');
    return null;
  }
});

// Provider pour vérifier si l'utilisateur est admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isAdmin();
});

// Notifier pour l'authentification
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final EnhancedAuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.data(null));

  // Connexion
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(email: email, password: password);
      
      // Charger les permissions après connexion réussie
      await _ref.read(permissionsProvider.notifier).loadUserPermissions();
      print('✅ Permissions chargées après connexion');
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Inscription
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      
      // Réinitialiser les permissions après déconnexion
      _ref.read(permissionsProvider.notifier).clear();
      print('✅ Permissions réinitialisées après déconnexion');
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _authService.resetPassword(email: email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider du notifier d'authentification
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
