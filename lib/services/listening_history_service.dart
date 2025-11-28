import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_chorale_audio_player/models/listening_history.dart';
import 'package:uuid/uuid.dart';

class ListeningHistoryService {
  static const String _historyKey = 'listening_history';
  static const int _maxHistoryItems = 100; // Garder les 100 dernières écoutes
  final _uuid = const Uuid();

  // Ajouter une écoute à l'historique
  Future<void> addListeningEntry({
    required String userId,
    required String chantId,
    required int durationListened,
    bool completed = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      List<ListeningHistory> history = [];
      if (historyJson != null) {
        final List<dynamic> jsonList = jsonDecode(historyJson);
        history = jsonList.map((json) => ListeningHistory.fromMap(json)).toList();
      }

      // Ajouter la nouvelle entrée
      final newEntry = ListeningHistory(
        id: _uuid.v4(),
        userId: userId,
        chantId: chantId,
        timestamp: DateTime.now(),
        durationListened: durationListened,
        completed: completed,
      );

      history.insert(0, newEntry); // Ajouter en début de liste

      // Limiter la taille de l'historique
      if (history.length > _maxHistoryItems) {
        history = history.sublist(0, _maxHistoryItems);
      }

      // Sauvegarder
      final historyListJson = history.map((h) => h.toMap()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyListJson));
    } catch (e) {
      print('Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  // Récupérer tout l'historique
  Future<List<ListeningHistory>> getHistory({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(historyJson);
      var history = jsonList.map((json) => ListeningHistory.fromMap(json)).toList();

      // Filtrer par userId si fourni
      if (userId != null) {
        history = history.where((h) => h.userId == userId).toList();
      }

      return history;
    } catch (e) {
      print('Erreur lors de la lecture de l\'historique: $e');
      return [];
    }
  }

  // Récupérer les chants récemment écoutés (uniques)
  Future<List<String>> getRecentlyListenedChantIds({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final history = await getHistory(userId: userId);
      
      // Obtenir les IDs uniques dans l'ordre chronologique
      final Set<String> uniqueIds = {};
      final List<String> recentIds = [];
      
      for (var entry in history) {
        if (!uniqueIds.contains(entry.chantId)) {
          uniqueIds.add(entry.chantId);
          recentIds.add(entry.chantId);
          
          if (recentIds.length >= limit) break;
        }
      }
      
      return recentIds;
    } catch (e) {
      print('Erreur lors de la récupération des chants récents: $e');
      return [];
    }
  }

  // Calculer les statistiques d'écoute
  Future<ListeningStats> getStats({required String userId}) async {
    try {
      final history = await getHistory(userId: userId);
      
      if (history.isEmpty) {
        return ListeningStats(
          totalListens: 0,
          totalDuration: 0,
          uniqueChants: 0,
          topChants: {},
        );
      }

      // Calculs
      final totalListens = history.length;
      final totalDuration = history.fold<int>(0, (sum, h) => sum + h.durationListened);
      
      // Compter les écoutes par chant
      final Map<String, int> chantCounts = {};
      for (var entry in history) {
        chantCounts[entry.chantId] = (chantCounts[entry.chantId] ?? 0) + 1;
      }
      
      final uniqueChants = chantCounts.length;
      
      // Trier par nombre d'écoutes (top chants)
      final sortedEntries = chantCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topChants = Map.fromEntries(sortedEntries.take(5));

      return ListeningStats(
        totalListens: totalListens,
        totalDuration: totalDuration,
        uniqueChants: uniqueChants,
        topChants: topChants,
        lastListened: history.first.timestamp,
      );
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return ListeningStats(
        totalListens: 0,
        totalDuration: 0,
        uniqueChants: 0,
        topChants: {},
      );
    }
  }

  // Vider l'historique
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Erreur lors du vidage de l\'historique: $e');
    }
  }

  // Supprimer une entrée spécifique
  Future<void> removeEntry(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) return;
      
      final List<dynamic> jsonList = jsonDecode(historyJson);
      var history = jsonList.map((json) => ListeningHistory.fromMap(json)).toList();
      
      history.removeWhere((h) => h.id == entryId);
      
      final historyListJson = history.map((h) => h.toMap()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyListJson));
    } catch (e) {
      print('Erreur lors de la suppression de l\'entrée: $e');
    }
  }
}
