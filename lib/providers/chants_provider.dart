import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/supabase_chants_service.dart';
import 'package:mini_chorale_audio_player/services/drift_chants_service.dart';
import 'package:mini_chorale_audio_player/providers/storage_providers.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'dart:async';

// Provider du service Supabase (pour sync)
final supabaseChantsServiceProvider = Provider<SupabaseChantsService>((ref) {
  return SupabaseChantsService();
});

// Provider de tous les chants avec Drift + Supabase
final chantsProvider = FutureProvider<List<Chant>>((ref) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  
  try {
    // 1. Charger depuis Drift (mode hors-ligne, ultra rapide)
    final cachedChants = await driftService.getAllChants();
    
    if (cachedChants.isNotEmpty) {
      print('📦 ${cachedChants.length} chants chargés depuis Drift');
      
      // 2. Synchroniser avec Supabase en arrière-plan
      _syncChantsInBackground(ref);
      
      return cachedChants;
    }
    
    // 3. Si pas de cache, charger depuis Supabase
    print('🌐 Chargement depuis Supabase...');
    final chants = await supabaseService.getAllChants();
    
    // 4. Sauvegarder dans Drift pour la prochaine fois
    await driftService.syncChantsFromSupabase(chants);
    
    return chants;
  } catch (e) {
    print('❌ Erreur: $e');
    rethrow;
  }
});

// Fonction pour synchroniser en arrière-plan
Future<void> _syncChantsInBackground(Ref ref) async {
  try {
    final supabaseService = ref.read(supabaseChantsServiceProvider);
    final driftService = ref.read(driftChantsServiceProvider);
    
    final chants = await supabaseService.getAllChants();
    await driftService.syncChantsFromSupabase(chants);
    
    print('🔄 Chants synchronisés avec Supabase');
  } catch (e) {
    print('⚠️ Erreur de synchronisation: $e');
  }
}

// Provider des chants par catégorie
final chantsByCategoryProvider =
    FutureProvider.family<List<Chant>, String>((ref, category) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  
  try {
    // Charger depuis Drift (rapide)
    return await driftService.getChantsByCategory(category);
  } catch (e) {
    print('❌ Erreur: $e');
    return [];
  }
});

// Provider de recherche de chants avec Drift
final searchChantsProvider =
    FutureProvider.family<List<Chant>, String>((ref, query) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  
  if (query.isEmpty) {
    // Si pas de query, retourner tous les chants
    return await driftService.getAllChants();
  }
  
  // Recherche dans Drift (ultra rapide)
  try {
    return await driftService.searchChants(query);
  } catch (e) {
    print('❌ Erreur de recherche: $e');
    return [];
  }
});

// Provider des catégories depuis Drift
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  
  try {
    // Essayer de récupérer depuis Drift d'abord
    final cachedChants = await driftService.getAllChants();
    
    if (cachedChants.isNotEmpty) {
      // Extraire les catégories uniques
      final categories = cachedChants
          .map((chant) => chant.categorie)
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return categories;
    }
    
    // Sinon, charger depuis Supabase
    final categories = await supabaseService.getAllCategories();
    return categories;
  } catch (e) {
    print('⚠️ Erreur lors de la récupération des catégories: $e');
    return [];
  }
});

// Provider du stream de chants (temps réel)
final chantsStreamProvider = StreamProvider<List<Chant>>((ref) {
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  return supabaseService.getChantsStream();
});

// Provider du stream de chants filtrés par type 'normal' (temps réel) avec Drift
final chantsNormalsStreamProvider = StreamProvider<List<Chant>>((ref) async* {
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  final driftService = ref.watch(driftChantsServiceProvider);
  
  // 🔥 NE PAS charger depuis Drift en premier pour éviter le flash
  // Charger directement depuis Supabase
  
  try {
    // Charger depuis Supabase
    await for (final chants in supabaseService.getChantsStream()) {
      final normalChants = chants.where((chant) => chant.type == 'normal').toList();
      
      // Mettre à jour Drift en arrière-plan
      driftService.syncChantsFromSupabase(normalChants).catchError((e) {
        print('⚠️ Erreur sync Drift: $e');
      });
      
      yield normalChants;
    }
  } catch (e) {
    print('⚠️ Connexion perdue, mode offline activé: $e');
    
    // En cas d'erreur, charger depuis Drift (mode offline)
    final cachedChants = await driftService.getChantsByType('normal');
    if (cachedChants.isNotEmpty) {
      yield cachedChants;
    }
  }
});

// Provider du stream de chants par catégorie (temps réel) avec Drift
final chantsByCategoryStreamProvider = 
    StreamProvider.family<List<Chant>, String>((ref, category) async* {
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  final driftService = ref.watch(driftChantsServiceProvider);
  
  // Charger depuis Drift d'abord
  final cachedChants = await driftService.getChantsByCategory(category);
  if (cachedChants.isNotEmpty) {
    yield cachedChants.where((chant) => chant.type == 'normal').toList();
  }
  
  // Essayer de se connecter au stream Supabase
  try {
    await for (final chants in supabaseService.getChantsStream()) {
      final filteredChants = chants
          .where((chant) => chant.categorie == category && chant.type == 'normal')
          .toList();
      yield filteredChants;
    }
  } catch (e) {
    print('Connexion perdue (catégorie $category), mode offline: $e');
  }
});

// Notifier pour la gestion des chants
class ChantsNotifier extends StateNotifier<AsyncValue<List<Chant>>> {
  final SupabaseChantsService _chantsService;

  ChantsNotifier(this._chantsService) : super(const AsyncValue.loading()) {
    loadChants();
  }

  // Charger les chants
  Future<void> loadChants() async {
    state = const AsyncValue.loading();
    try {
      final chants = await _chantsService.getAllChants();
      state = AsyncValue.data(chants);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Ajouter un chant
  Future<void> addChant({
    required String titre,
    required String categorie,
    required String auteur,
    required String urlAudio,
    required int duree,
    String type = 'normal',
  }) async {
    try {
      await _chantsService.addChant(
        titre: titre,
        categorie: categorie,
        auteur: auteur,
        urlAudio: urlAudio,
        duree: duree,
        type: type,
      );
      // Pas besoin de loadChants() - le StreamProvider se met à jour automatiquement
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour un chant
  Future<void> updateChant({
    required String id,
    String? titre,
    String? categorie,
    String? auteur,
    String? urlAudio,
    int? duree,
    String? lyrics,
    String? partitionUrl,
  }) async {
    try {
      await _chantsService.updateChant(
        id: id,
        titre: titre,
        categorie: categorie,
        auteur: auteur,
        urlAudio: urlAudio,
        duree: duree,
        lyrics: lyrics,
        partitionUrl: partitionUrl,
      );
      // Le StreamProvider se met à jour automatiquement via Supabase Realtime
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un chant avec mise à jour optimiste
  Future<void> deleteChant(String id) async {
    final currentChants = state.value ?? [];
    
    // Mise à jour optimiste : retirer immédiatement de la liste
    state = AsyncValue.data(
      currentChants.where((c) => c.id != id).toList(),
    );
    
    // Appel serveur en arrière-plan
    try {
      await _chantsService.deleteChant(id);
    } catch (e) {
      // En cas d'erreur, restaurer le chant
      state = AsyncValue.data(currentChants);
      rethrow;
    }
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    state.whenData((chants) {
      final filtered = chants.where((c) => c.categorie == category).toList();
      state = AsyncValue.data(filtered);
    });
  }

  // Rechercher
  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadChants();
      return;
    }

    try {
      final results = await _chantsService.searchChants(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider du notifier de chants
final chantsNotifierProvider =
    StateNotifierProvider<ChantsNotifier, AsyncValue<List<Chant>>>((ref) {
  final chantsService = ref.watch(supabaseChantsServiceProvider);
  return ChantsNotifier(chantsService);
});

// Provider des chants par type
final chantsByTypeProvider =
    FutureProvider.family<List<Chant>, String>((ref, type) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  return await driftService.getChantsByType(type);
});

// Provider des chants normaux
final chantsNormalsProvider = FutureProvider<List<Chant>>((ref) async {
  return ref.watch(chantsByTypeProvider('normal').future);
});

// Provider des chants par pupitre
final chantsPupitreProvider = FutureProvider<List<Chant>>((ref) async {
  return ref.watch(chantsByTypeProvider('pupitre').future);
});

// Provider des chants d'un pupitre spécifique
final chantsByPupitreProvider =
    FutureProvider.family<List<Chant>, String>((ref, pupitre) async {
  final driftService = ref.watch(driftChantsServiceProvider);
  // Filtrer par pupitre (catégorie)
  final allChants = await driftService.getChantsByType('pupitre');
  return allChants.where((chant) => chant.categorie == pupitre).toList();
});

// Provider du stream de chants par pupitre (temps réel) avec Drift
final chantsPupitreStreamProvider = StreamProvider<List<Chant>>((ref) async* {
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  final driftService = ref.watch(driftChantsServiceProvider);
  
  // Charger depuis Drift d'abord
  final cachedChants = await driftService.getChantsByType('pupitre');
  if (cachedChants.isNotEmpty) {
    yield cachedChants;
  }
  
  // Essayer de se connecter au stream Supabase
  try {
    await for (final chants in supabaseService.getChantsStream()) {
      final pupitreChants = chants.where((chant) => chant.type == 'pupitre').toList();
      yield pupitreChants;
    }
  } catch (e) {
    print('Connexion perdue (pupitres), mode offline: $e');
  }
});

// Provider du stream de chants d'un pupitre spécifique (temps réel) avec Drift
final chantsByPupitreStreamProvider = 
    StreamProvider.family<List<Chant>, String>((ref, pupitre) async* {
  final supabaseService = ref.watch(supabaseChantsServiceProvider);
  final driftService = ref.watch(driftChantsServiceProvider);
  
  // Charger depuis Drift d'abord
  final cachedChants = await driftService.getChantsByType('pupitre');
  if (cachedChants.isNotEmpty) {
    yield cachedChants
        .where((chant) => chant.categorie == pupitre)
        .toList();
  }
  
  // Essayer de se connecter au stream Supabase
  try {
    await for (final chants in supabaseService.getChantsStream()) {
      final filteredChants = chants
          .where((chant) => chant.type == 'pupitre' && chant.categorie == pupitre)
          .toList();
      yield filteredChants;
    }
  } catch (e) {
    print('Connexion perdue (pupitre $pupitre), mode offline: $e');
  }
});
