import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_service_provider.dart';
import '../providers/permissions_provider_riverpod.dart';

/// Controller pour gérer l'authentification avec permissions
class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AuthController(this.ref) : super(const AsyncValue.data(null));

  /// Connexion avec chargement des permissions
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      // 1. Connexion via EnhancedAuthService
      final authService = ref.read(enhancedAuthServiceProvider);
      await authService.signIn(email: email, password: password);
      
      // 2. Charger les permissions
      await ref.read(permissionsProvider.notifier).loadUserPermissions();
      
      print('✅ Connexion et permissions chargées avec succès');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('❌ Erreur connexion: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Déconnexion avec nettoyage des permissions
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      // 1. Déconnexion via EnhancedAuthService
      final authService = ref.read(enhancedAuthServiceProvider);
      await authService.signOut();
      
      // 2. Réinitialiser les permissions
      ref.read(permissionsProvider.notifier).clear();
      
      print('✅ Déconnexion et permissions réinitialisées');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('❌ Erreur déconnexion: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Inscription
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final authService = ref.read(enhancedAuthServiceProvider);
      await authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      print('✅ Inscription réussie');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('❌ Erreur inscription: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider pour AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
