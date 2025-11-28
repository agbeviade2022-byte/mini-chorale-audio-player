import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de cache pour les favoris en mode hors ligne
class FavoritesCacheService {
  static const String _cacheKey = 'cached_favorites';
  static const String _userIdKey = 'cached_favorites_user_id';
  static const String _lastUpdateKey = 'favorites_last_update';

  /// Sauvegarder les favoris en cache pour un utilisateur
  Future<void> cacheFavorites(String userId, List<String> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(favorites));
      await prefs.setString(_userIdKey, userId);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      print('💾 Favoris mis en cache: ${favorites.length} favoris pour user $userId');
    } catch (e) {
      print('❌ Erreur lors de la mise en cache des favoris: $e');
    }
  }

  /// Récupérer les favoris depuis le cache pour un utilisateur
  Future<List<String>?> getCachedFavorites(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString(_userIdKey);
      
      // Vérifier que c'est bien le même utilisateur
      if (cachedUserId != userId) {
        print('⚠️ Cache favoris pour un autre utilisateur, ignoré');
        return null;
      }
      
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData == null) {
        print('💾 Aucun cache de favoris trouvé');
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(cachedData);
      final favorites = jsonList.map((item) => item as String).toList();
      print('💾 Favoris chargés depuis le cache: ${favorites.length} favoris');
      return favorites;
    } catch (e) {
      print('❌ Erreur lors de la lecture du cache des favoris: $e');
      return null;
    }
  }

  /// Obtenir la date de dernière mise à jour
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateKey);
      
      if (timestamp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('❌ Erreur lors de la lecture de la date: $e');
      return null;
    }
  }

  /// Vider le cache des favoris
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_lastUpdateKey);
      print('🗑️ Cache des favoris vidé');
    } catch (e) {
      print('❌ Erreur lors du vidage du cache des favoris: $e');
    }
  }

  /// Ajouter un favori au cache (mise à jour optimiste)
  Future<void> addToCache(String userId, String chantId) async {
    try {
      final cachedFavorites = await getCachedFavorites(userId) ?? [];
      if (!cachedFavorites.contains(chantId)) {
        cachedFavorites.add(chantId);
        await cacheFavorites(userId, cachedFavorites);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout au cache: $e');
    }
  }

  /// Retirer un favori du cache (mise à jour optimiste)
  Future<void> removeFromCache(String userId, String chantId) async {
    try {
      final cachedFavorites = await getCachedFavorites(userId) ?? [];
      cachedFavorites.remove(chantId);
      await cacheFavorites(userId, cachedFavorites);
    } catch (e) {
      print('❌ Erreur lors du retrait du cache: $e');
    }
  }
}
