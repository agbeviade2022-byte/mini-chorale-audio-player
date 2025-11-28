import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hive_session_service.dart';
import 'drift_chants_service.dart';
import 'secure_storage_service.dart';

/// Service pour gérer l'état global de l'application
/// Gère le nettoyage complet au logout et le rechargement au login
class AppStateManager {
  final HiveSessionService _hiveSession;
  final DriftChantsService _driftChants;
  final SecureStorageService _secureStorage;
  final SupabaseClient _supabase;

  AppStateManager({
    required HiveSessionService hiveSession,
    required DriftChantsService driftChants,
    required SecureStorageService secureStorage,
    required SupabaseClient supabase,
  })  : _hiveSession = hiveSession,
        _driftChants = driftChants,
        _secureStorage = secureStorage,
        _supabase = supabase;

  /// 🔥 NETTOYAGE COMPLET AU LOGOUT
  /// Efface TOUTES les données de l'ancien utilisateur
  Future<void> resetAppState() async {
    try {
      debugPrint('🧹 Début du nettoyage de l\'état de l\'application...');

      // 1. Effacer la session Hive
      await _hiveSession.clearSession();
      debugPrint('✅ Session Hive effacée');

      // 2. Effacer tous les chants Drift
      await _driftChants.clearAllData();
      debugPrint('✅ Base de données Drift effacée');

      // 3. Effacer les tokens sécurisés
      await _secureStorage.deleteToken();
      await _secureStorage.deleteRefreshToken();
      debugPrint('✅ Tokens sécurisés effacés');

      // 4. Effacer toutes les boxes Hive
      await _clearAllHiveBoxes();
      debugPrint('✅ Toutes les boxes Hive effacées');

      // 5. Déconnecter Supabase
      await _supabase.auth.signOut();
      debugPrint('✅ Supabase déconnecté');

      debugPrint('✅✅✅ Nettoyage complet terminé');
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage: $e');
      rethrow;
    }
  }

  /// Effacer toutes les boxes Hive
  Future<void> _clearAllHiveBoxes() async {
    try {
      // Liste de toutes vos boxes
      final boxNames = [
        'userSession',
        'appSettings',
        'userPreferences',
        'cache',
      ];

      for (final boxName in boxNames) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          debugPrint('  ✅ Box "$boxName" effacée');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'effacement des boxes: $e');
    }
  }

  /// 🔄 RECHARGEMENT COMPLET AU LOGIN
  /// Charge TOUTES les données du nouvel utilisateur
  Future<void> loadUserData(String userId) async {
    try {
      debugPrint('🔄 Chargement des données utilisateur: $userId');

      // 1. Charger le profil utilisateur
      final profile = await _loadUserProfile(userId);
      debugPrint('✅ Profil chargé: ${profile['full_name']}');

      // 2. Sauvegarder dans Hive
      await _hiveSession.updateProfile(profile);
      debugPrint('✅ Profil sauvegardé dans Hive');

      // 3. Synchroniser les chants depuis Supabase
      await _syncUserChants(userId, profile['chorale_id']);
      debugPrint('✅ Chants synchronisés');

      // 4. Charger les favoris
      await _syncUserFavorites(userId);
      debugPrint('✅ Favoris synchronisés');

      // 5. Charger les playlists
      await _syncUserPlaylists(userId);
      debugPrint('✅ Playlists synchronisées');

      debugPrint('✅✅✅ Données utilisateur chargées avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des données: $e');
      rethrow;
    }
  }

  /// Charger le profil utilisateur depuis Supabase
  Future<Map<String, dynamic>> _loadUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('user_id, full_name, role, chorale_id, statut_validation, telephone')
        .eq('user_id', userId)
        .single();

    return response;
  }

  /// Synchroniser les chants de la chorale de l'utilisateur
  Future<void> _syncUserChants(String userId, String? choraleId) async {
    if (choraleId == null) {
      debugPrint('⚠️ Utilisateur sans chorale, pas de chants à synchroniser');
      return;
    }

    // Récupérer les chants de la chorale
    final chants = await _supabase
        .from('chants')
        .select('*')
        .eq('chorale_id', choraleId);

    // Sauvegarder dans Drift
    await _driftChants.syncChantsFromSupabase(chants);
    debugPrint('  ✅ ${chants.length} chants synchronisés');
  }

  /// Synchroniser les favoris de l'utilisateur
  Future<void> _syncUserFavorites(String userId) async {
    // Récupérer les favoris depuis Supabase
    final favorites = await _supabase
        .from('favoris')
        .select('chant_id')
        .eq('user_id', userId);

    // Sauvegarder dans Drift
    for (final fav in favorites) {
      await _driftChants.addFavorite(fav['chant_id']);
    }
    debugPrint('  ✅ ${favorites.length} favoris synchronisés');
  }

  /// Synchroniser les playlists de l'utilisateur
  Future<void> _syncUserPlaylists(String userId) async {
    // Récupérer les playlists depuis Supabase
    final playlists = await _supabase
        .from('playlists')
        .select('*')
        .eq('user_id', userId);

    debugPrint('  ✅ ${playlists.length} playlists synchronisées');
  }

  /// 🔐 LOGOUT COMPLET
  /// Nettoie tout et redirige vers le login
  Future<void> logout() async {
    try {
      debugPrint('🚪 Déconnexion en cours...');

      // Nettoyer complètement l'état
      await resetAppState();

      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  /// 🔑 LOGIN COMPLET
  /// Se connecte et charge toutes les données
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('🔑 Connexion en cours...');

      // 1. Nettoyer les anciennes données (au cas où)
      await resetAppState();

      // 2. Se connecter à Supabase
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Échec de la connexion');
      }

      final userId = authResponse.user!.id;
      final token = authResponse.session?.accessToken;

      debugPrint('✅ Connexion Supabase réussie: $userId');

      // 3. Sauvegarder le token
      if (token != null) {
        await _secureStorage.saveToken(token);
        await _hiveSession.updateToken(token);
      }

      // 4. Charger TOUTES les données du nouvel utilisateur
      await loadUserData(userId);

      // 5. Retourner les infos de l'utilisateur
      final profile = await _loadUserProfile(userId);

      debugPrint('✅✅✅ Connexion complète réussie');

      return {
        'user_id': userId,
        'email': email,
        'profile': profile,
      };
    } catch (e) {
      debugPrint('❌ Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Vérifier si un utilisateur est connecté
  Future<bool> isUserLoggedIn() async {
    final session = await _hiveSession.getSession();
    return session != null && session.token.isNotEmpty;
  }

  /// Obtenir l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final session = await _hiveSession.getSession();
    if (session == null) return null;

    return {
      'user_id': session.userId,
      'profile': session.profile,
    };
  }
}
