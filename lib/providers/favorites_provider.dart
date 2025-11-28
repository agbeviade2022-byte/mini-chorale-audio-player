import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/supabase_favorites_service.dart';
import 'package:mini_chorale_audio_player/services/drift_chants_service.dart';
import 'package:mini_chorale_audio_player/providers/storage_providers.dart';
import 'package:mini_chorale_audio_player/providers/auth_provider.dart';

// Provider du service Supabase de favoris
final supabaseFavoritesServiceProvider = Provider<SupabaseFavoritesService>((ref) {
  return SupabaseFavoritesService();
});

// Provider du stream des favoris (temps réel)
final favoritesStreamProvider = StreamProvider<List<String>>((ref) {
  final favoritesService = ref.watch(supabaseFavoritesServiceProvider);
  return favoritesService.getFavoritesStream();
});

// Provider pour vérifier si un chant est favori (avec Drift)
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, chantId) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) return false;
  
  return await driftService.isFavorite(currentUser.id, chantId);
});

// Notifier pour gérer les favoris avec Drift + Supabase
class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final DriftChantsService _driftService;
  final SupabaseFavoritesService _supabaseService;
  final String? _userId;

  FavoritesNotifier(this._driftService, this._supabaseService, this._userId) 
      : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  // Charger les favoris depuis Drift
  Future<void> loadFavorites() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      // Charger depuis Drift (rapide)
      final favorites = await _driftService.getUserFavoriteIds(_userId!);
      state = AsyncValue.data(favorites);
      
      // Synchroniser avec Supabase en arrière-plan
      _syncFavoritesInBackground();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  // Synchroniser avec Supabase en arrière-plan
  Future<void> _syncFavoritesInBackground() async {
    if (_userId == null) return;
    
    try {
      final supabaseFavorites = await _supabaseService.getUserFavorites();
      await _driftService.syncFavoritesFromSupabase(_userId!, supabaseFavorites);
      print('🔄 Favoris synchronisés avec Supabase');
    } catch (e) {
      print('⚠️ Erreur de synchronisation des favoris: $e');
    }
  }

  // Toggle favori avec mise à jour optimiste (Drift + Supabase)
  Future<void> toggleFavorite(String chantId) async {
    if (_userId == null) return;
    
    final currentFavorites = state.value ?? [];
    final isFav = currentFavorites.contains(chantId);
    
    // Mise à jour optimiste immédiate dans l'UI
    if (isFav) {
      state = AsyncValue.data(
        currentFavorites.where((id) => id != chantId).toList(),
      );
    } else {
      state = AsyncValue.data([...currentFavorites, chantId]);
    }
    
    // Mettre à jour Drift immédiatement (local)
    try {
      if (isFav) {
        await _driftService.removeFavorite(_userId!, chantId);
      } else {
        await _driftService.addFavorite(_userId!, chantId);
      }
      
      // Synchroniser avec Supabase en arrière-plan
      _supabaseService.toggleFavorite(chantId).catchError((e) {
        print('⚠️ Erreur sync Supabase: $e');
      });
    } catch (e) {
      // En cas d'erreur, revenir à l'état précédent
      state = AsyncValue.data(currentFavorites);
      rethrow;
    }
  }

  // Vérifier si un chant est favori
  bool isFavorite(String chantId) {
    return state.value?.contains(chantId) ?? false;
  }
}

// Provider du notifier de favoris
final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  final driftService = ref.watch(driftChantsServiceProvider);
  final supabaseService = ref.watch(supabaseFavoritesServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  return FavoritesNotifier(driftService, supabaseService, currentUser?.id);
});
