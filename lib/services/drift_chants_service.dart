import 'package:drift/drift.dart';
import 'package:mini_chorale_audio_player/database/drift_database.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:uuid/uuid.dart';

/// Service pour gérer les chants avec Drift (SQLite)
/// 🥈 Remplace SharedPreferences pour le stockage massif de chants
class DriftChantsService {
  final AppDatabase _database;
  final _uuid = const Uuid();

  DriftChantsService(this._database);

  // ==================== CHANTS ====================

  /// Synchroniser les chants depuis Supabase vers la DB locale
  Future<void> syncChantsFromSupabase(List<Chant> chants) async {
    try {
      final companions = chants.map((chant) {
        return ChantsTableCompanion(
          id: Value(chant.id),
          titre: Value(chant.titre),
          categorie: Value(chant.categorie),
          auteur: Value(chant.auteur),
          urlAudio: Value(chant.urlAudio),
          duree: Value(chant.duree),
          createdAt: Value(chant.createdAt),
          type: Value(chant.type),
          lyrics: Value(chant.lyrics),
          partitionUrl: Value(chant.partitionUrl),
          isCached: const Value(true),
          lastSyncedAt: Value(DateTime.now()),
        );
      }).toList();

      await _database.upsertChants(companions);
      print('✅ ${chants.length} chants synchronisés vers Drift');
    } catch (e) {
      print('❌ Erreur lors de la synchronisation des chants: $e');
      rethrow;
    }
  }

  /// Récupérer tous les chants depuis la DB locale
  Future<List<Chant>> getAllChants() async {
    try {
      final chantsData = await _database.getAllChants();
      return chantsData.map(_convertToChant).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des chants: $e');
      return [];
    }
  }

  /// Récupérer un chant par ID
  Future<Chant?> getChantById(String id) async {
    try {
      final chantData = await _database.getChantById(id);
      return chantData != null ? _convertToChant(chantData) : null;
    } catch (e) {
      print('❌ Erreur lors de la récupération du chant: $e');
      return null;
    }
  }

  /// Rechercher des chants
  Future<List<Chant>> searchChants(String query) async {
    try {
      final chantsData = await _database.searchChants(query);
      return chantsData.map(_convertToChant).toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// Filtrer par catégorie
  Future<List<Chant>> getChantsByCategory(String category) async {
    try {
      final chantsData = await _database.getChantsByCategory(category);
      return chantsData.map(_convertToChant).toList();
    } catch (e) {
      print('❌ Erreur lors du filtrage: $e');
      return [];
    }
  }

  /// Filtrer par type (normal ou pupitre)
  Future<List<Chant>> getChantsByType(String type) async {
    try {
      final chantsData = await _database.getChantsByType(type);
      return chantsData.map(_convertToChant).toList();
    } catch (e) {
      print('❌ Erreur lors du filtrage: $e');
      return [];
    }
  }

  // ==================== FAVORIS ====================

  /// Récupérer les IDs des favoris d'un utilisateur
  Future<List<String>> getUserFavoriteIds(String userId) async {
    try {
      final favorites = await _database.getUserFavorites(userId);
      return favorites.map((f) => f.chantId).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }

  /// Récupérer les chants favoris d'un utilisateur
  Future<List<Chant>> getUserFavoriteChants(String userId) async {
    try {
      final favoriteIds = await getUserFavoriteIds(userId);
      final allChants = await getAllChants();
      return allChants.where((c) => favoriteIds.contains(c.id)).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des chants favoris: $e');
      return [];
    }
  }

  /// Ajouter un favori
  Future<void> addFavorite(String userId, String chantId) async {
    try {
      final favorite = FavoritesTableCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId),
        chantId: Value(chantId),
        createdAt: Value(DateTime.now()),
        isSynced: const Value(false),
      );
      await _database.addFavorite(favorite);
      print('⭐ Favori ajouté: $chantId');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du favori: $e');
      rethrow;
    }
  }

  /// Retirer un favori
  Future<void> removeFavorite(String userId, String chantId) async {
    try {
      await _database.removeFavorite(userId, chantId);
      print('⭐ Favori retiré: $chantId');
    } catch (e) {
      print('❌ Erreur lors du retrait du favori: $e');
      rethrow;
    }
  }

  /// Vérifier si un chant est favori
  Future<bool> isFavorite(String userId, String chantId) async {
    try {
      return await _database.isFavorite(userId, chantId);
    } catch (e) {
      print('❌ Erreur lors de la vérification du favori: $e');
      return false;
    }
  }

  /// Synchroniser les favoris depuis Supabase
  Future<void> syncFavoritesFromSupabase(
      String userId, List<String> favoriteIds) async {
    try {
      // Supprimer les anciens favoris
      final currentFavorites = await _database.getUserFavorites(userId);
      for (final fav in currentFavorites) {
        if (!favoriteIds.contains(fav.chantId)) {
          await _database.removeFavorite(userId, fav.chantId);
        }
      }

      // Ajouter les nouveaux favoris
      for (final chantId in favoriteIds) {
        final exists = await _database.isFavorite(userId, chantId);
        if (!exists) {
          await addFavorite(userId, chantId);
        }
      }

      print('✅ Favoris synchronisés: ${favoriteIds.length} favoris');
    } catch (e) {
      print('❌ Erreur lors de la synchronisation des favoris: $e');
      rethrow;
    }
  }

  // ==================== HISTORIQUE ====================

  /// Ajouter une écoute à l'historique
  Future<void> addToHistory({
    required String userId,
    required String chantId,
    required int duration,
    bool completed = false,
  }) async {
    try {
      final history = ListeningHistoryTableCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId),
        chantId: Value(chantId),
        listenedAt: Value(DateTime.now()),
        duration: Value(duration),
        completed: Value(completed),
        isSynced: const Value(false),
      );
      await _database.addToHistory(history);
      print('📊 Historique ajouté: $chantId');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// Récupérer l'historique d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserHistory(String userId,
      {int limit = 50}) async {
    try {
      final history = await _database.getUserHistory(userId, limit: limit);
      return history.map((h) {
        return {
          'id': h.id,
          'chantId': h.chantId,
          'listenedAt': h.listenedAt,
          'duration': h.duration,
          'completed': h.completed,
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  // ==================== TÉLÉCHARGEMENTS ====================

  /// Marquer un chant comme téléchargé
  Future<void> markAsDownloaded({
    required String chantId,
    required String localPath,
    required int fileSize,
  }) async {
    try {
      final download = DownloadedChantsTableCompanion(
        id: Value(_uuid.v4()),
        chantId: Value(chantId),
        localPath: Value(localPath),
        fileSize: Value(fileSize),
        downloadedAt: Value(DateTime.now()),
        status: const Value('completed'),
      );
      await _database.addDownload(download);
      print('📥 Chant téléchargé: $chantId');
    } catch (e) {
      print('❌ Erreur lors du marquage du téléchargement: $e');
    }
  }

  /// Vérifier si un chant est téléchargé
  Future<bool> isDownloaded(String chantId) async {
    try {
      return await _database.isDownloaded(chantId);
    } catch (e) {
      print('❌ Erreur lors de la vérification du téléchargement: $e');
      return false;
    }
  }

  /// Récupérer tous les chants téléchargés
  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    try {
      final downloads = await _database.getAllDownloads();
      return downloads.map((d) {
        return {
          'id': d.id,
          'chantId': d.chantId,
          'localPath': d.localPath,
          'fileSize': d.fileSize,
          'downloadedAt': d.downloadedAt,
          'status': d.status,
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des téléchargements: $e');
      return [];
    }
  }

  // ==================== NETTOYAGE ====================

  /// Vider toutes les données
  Future<void> clearAllData() async {
    try {
      await _database.clearAllData();
      print('🗑️ Toutes les données Drift supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression des données: $e');
    }
  }

  /// Vider les données d'un utilisateur
  Future<void> clearUserData(String userId) async {
    try {
      await _database.clearUserData(userId);
      print('🗑️ Données utilisateur supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression des données utilisateur: $e');
    }
  }

  // ==================== CONVERSION ====================

  /// Convertir ChantsTableData en Chant
  Chant _convertToChant(ChantsTableData data) {
    return Chant(
      id: data.id,
      titre: data.titre,
      categorie: data.categorie,
      auteur: data.auteur,
      urlAudio: data.urlAudio,
      duree: data.duree,
      createdAt: data.createdAt,
      type: data.type,
      lyrics: data.lyrics,
      partitionUrl: data.partitionUrl,
    );
  }
}
