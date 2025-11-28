import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/models/listening_history.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/services/listening_history_service.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';

// Provider du service d'historique
final listeningHistoryServiceProvider = Provider<ListeningHistoryService>((ref) {
  return ListeningHistoryService();
});

// Provider de l'historique complet
final listeningHistoryProvider = FutureProvider<List<ListeningHistory>>((ref) async {
  final service = ref.watch(listeningHistoryServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return [];
  
  return await service.getHistory(userId: user.id);
});

// Provider des chants récemment écoutés (avec détails complets)
// UNIQUEMENT les chants normaux (pas les chants pupitre)
final recentlyListenedChantsProvider = FutureProvider<List<Chant>>((ref) async {
  final service = ref.watch(listeningHistoryServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return [];
  
  final recentIds = await service.getRecentlyListenedChantIds(
    userId: user.id,
    limit: 6, // Récupérer 6 pour avoir au moins 3 chants normaux après filtrage
  );
  
  // Récupérer les détails des chants ET filtrer pour exclure les chants pupitre
  // Maintenir l'ordre de récence et limiter à 3 chants
  final allChants = await ref.watch(chantsProvider.future);
  final result = <Chant>[];
  for (final id in recentIds) {
    if (result.length >= 3) break; // Limiter à 3 chants
    
    try {
      final chant = allChants.firstWhere((c) => c.id == id);
      // Ajouter uniquement les chants normaux (pas les pupitre)
      if (chant.type != 'pupitre') {
        result.add(chant);
      }
    } catch (_) {
      // Chant supprimé ou introuvable, on l'ignore
      continue;
    }
  }
  return result;
});

// Provider des chants PUPITRE récemment écoutés (séparé des chants normaux)
final recentlyListenedPupitreChantsProvider = FutureProvider<List<Chant>>((ref) async {
  final service = ref.watch(listeningHistoryServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return [];
  
  final recentIds = await service.getRecentlyListenedChantIds(
    userId: user.id,
    limit: 6, // Récupérer 6 pour avoir au moins 3 chants pupitre après filtrage
  );
  
  // Récupérer uniquement les chants pupitre
  // Maintenir l'ordre de récence et limiter à 3 chants
  final allChants = await ref.watch(chantsProvider.future);
  final result = <Chant>[];
  for (final id in recentIds) {
    if (result.length >= 3) break; // Limiter à 3 chants
    
    try {
      final chant = allChants.firstWhere((c) => c.id == id);
      // Ajouter uniquement les chants pupitre
      if (chant.type == 'pupitre') {
        result.add(chant);
      }
    } catch (_) {
      // Chant supprimé ou introuvable, on l'ignore
      continue;
    }
  }
  return result;
});

// Provider des statistiques d'écoute
final listeningStatsProvider = FutureProvider<ListeningStats>((ref) async {
  final service = ref.watch(listeningHistoryServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return ListeningStats(
      totalListens: 0,
      totalDuration: 0,
      uniqueChants: 0,
      topChants: {},
    );
  }
  
  return await service.getStats(userId: user.id);
});

// Provider des top chants (avec détails complets)
final topListenedChantsProvider = FutureProvider<List<Chant>>((ref) async {
  final stats = await ref.watch(listeningStatsProvider.future);
  final allChants = await ref.watch(chantsProvider.future);
  
  // Obtenir les chants correspondant aux top IDs
  final topChantIds = stats.topChants.keys.toList();
  return allChants.where((chant) => topChantIds.contains(chant.id)).toList();
});

// Notifier pour gérer l'ajout à l'historique
class ListeningHistoryNotifier extends StateNotifier<AsyncValue<void>> {
  final ListeningHistoryService _service;
  final Ref _ref;

  ListeningHistoryNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  // Enregistrer une écoute
  Future<void> recordListen({
    required String chantId,
    required int durationListened,
    bool completed = false,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      await _service.addListeningEntry(
        userId: user.id,
        chantId: chantId,
        durationListened: durationListened,
        completed: completed,
      );

      // Rafraîchir les providers
      _ref.invalidate(listeningHistoryProvider);
      _ref.invalidate(recentlyListenedChantsProvider);
      _ref.invalidate(listeningStatsProvider);
      _ref.invalidate(topListenedChantsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Vider l'historique
  Future<void> clearHistory() async {
    try {
      await _service.clearHistory();
      
      // Rafraîchir les providers
      _ref.invalidate(listeningHistoryProvider);
      _ref.invalidate(recentlyListenedChantsProvider);
      _ref.invalidate(listeningStatsProvider);
      _ref.invalidate(topListenedChantsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider du notifier d'historique
final listeningHistoryNotifierProvider = 
    StateNotifierProvider<ListeningHistoryNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(listeningHistoryServiceProvider);
  return ListeningHistoryNotifier(service, ref);
});
