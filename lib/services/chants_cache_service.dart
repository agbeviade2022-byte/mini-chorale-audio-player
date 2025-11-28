import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';

class ChantsCacheService {
  static const String _cacheKey = 'cached_chants';
  static const String _lastUpdateKey = 'chants_last_update';

  // Sauvegarder les chants en cache
  Future<void> cacheChants(List<Chant> chants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chantsJson = chants.map((c) => c.toMap()).toList();
      await prefs.setString(_cacheKey, jsonEncode(chantsJson));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erreur lors de la mise en cache: $e');
    }
  }

  // Récupérer les chants depuis le cache
  Future<List<Chant>?> getCachedChants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList.map((json) => Chant.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors de la lecture du cache: $e');
      return null;
    }
  }

  // Obtenir la date de dernière mise à jour
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateKey);
      
      if (timestamp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Erreur lors de la lecture de la date: $e');
      return null;
    }
  }

  // Vider le cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      print('Erreur lors du vidage du cache: $e');
    }
  }
}
