import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/services/favorites_cache_service.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FavoritesCacheService _favoritesCacheService = FavoritesCacheService();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _supabase.auth.currentUser;

  // Stream de l'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Inscription
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      // Le profil est créé automatiquement par le trigger Supabase
      // Pas besoin de l'insérer manuellement

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Connexion
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      // Nettoyer le cache des favoris avant de se déconnecter
      await _favoritesCacheService.clearCache();
      print('🗑️ Cache des favoris nettoyé lors de la déconnexion');
      
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le mot de passe
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Obtenir le profil utilisateur
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase.from('profiles').update(data).eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier si l'utilisateur est admin
  Future<bool> isAdmin() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}
