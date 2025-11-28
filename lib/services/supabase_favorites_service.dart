import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/services/favorites_cache_service.dart';

class SupabaseFavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FavoritesCacheService _cacheService = FavoritesCacheService();

  // Ajouter un chant aux favoris
  Future<void> addToFavorites(String chantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Mise à jour optimiste du cache
      await _cacheService.addToCache(userId, chantId);

      // Puis mise à jour serveur
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'chant_id': chantId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Retirer un chant des favoris
  Future<void> removeFromFavorites(String chantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Mise à jour optimiste du cache
      await _cacheService.removeFromCache(userId, chantId);

      // Puis mise à jour serveur
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('chant_id', chantId);
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier si un chant est en favori
  Future<bool> isFavorite(String chantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('chant_id', chantId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Récupérer tous les favoris de l'utilisateur
  Future<List<String>> getUserFavorites() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Essayer de récupérer depuis le serveur
      try {
        final response = await _supabase
            .from('favorites')
            .select('chant_id')
            .eq('user_id', userId);

        final favorites = (response as List)
            .map((item) => item['chant_id'] as String)
            .toList();
        
        // Mettre à jour le cache
        await _cacheService.cacheFavorites(userId, favorites);
        
        return favorites;
      } catch (e) {
        // En cas d'erreur (pas de connexion), utiliser le cache
        print('⚠️ Erreur serveur, utilisation du cache: $e');
        final cachedFavorites = await _cacheService.getCachedFavorites(userId);
        return cachedFavorites ?? [];
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }

  // Stream des favoris de l'utilisateur (temps réel)
  Stream<List<String>> getFavoritesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((item) => item['chant_id'] as String).toList());
  }

  // Toggle favori (ajouter ou retirer)
  Future<bool> toggleFavorite(String chantId) async {
    final isFav = await isFavorite(chantId);
    if (isFav) {
      await removeFromFavorites(chantId);
      return false;
    } else {
      await addToFavorites(chantId);
      return true;
    }
  }
}
