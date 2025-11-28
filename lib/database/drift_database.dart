import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'drift_database.g.dart';

/// Table pour stocker les chants en local
class ChantsTable extends Table {
  TextColumn get id => text()();
  TextColumn get titre => text()();
  TextColumn get categorie => text()();
  TextColumn get auteur => text()();
  TextColumn get urlAudio => text()();
  IntColumn get duree => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get type => text().withDefault(const Constant('normal'))();
  TextColumn get lyrics => text().nullable()();
  TextColumn get partitionUrl => text().nullable()();
  BoolColumn get isCached => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table pour stocker les favoris en local
class FavoritesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get chantId => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table pour stocker les playlists
class PlaylistsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table pour stocker les chants dans les playlists
class PlaylistChantsTable extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text()();
  TextColumn get chantId => text()();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table pour stocker l'historique d'écoute
class ListeningHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get chantId => text()();
  DateTimeColumn get listenedAt => dateTime()();
  IntColumn get duration => integer()(); // Durée écoutée en secondes
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table pour stocker les chants téléchargés
class DownloadedChantsTable extends Table {
  TextColumn get id => text()();
  TextColumn get chantId => text()();
  TextColumn get localPath => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get downloadedAt => dateTime()();
  TextColumn get status => text()(); // 'completed', 'pending', 'failed'

  @override
  Set<Column> get primaryKey => {id};
}

/// Base de données Drift principale
@DriftDatabase(tables: [
  ChantsTable,
  FavoritesTable,
  PlaylistsTable,
  PlaylistChantsTable,
  ListeningHistoryTable,
  DownloadedChantsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ==================== CHANTS ====================

  /// Récupérer tous les chants
  Future<List<ChantsTableData>> getAllChants() => select(chantsTable).get();

  /// Récupérer un chant par ID
  Future<ChantsTableData?> getChantById(String id) =>
      (select(chantsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insérer ou mettre à jour un chant
  Future<void> upsertChant(ChantsTableCompanion chant) =>
      into(chantsTable).insertOnConflictUpdate(chant);

  /// Insérer ou mettre à jour plusieurs chants
  Future<void> upsertChants(List<ChantsTableCompanion> chants) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(chantsTable, chants);
    });
  }

  /// Supprimer un chant
  Future<void> deleteChant(String id) =>
      (delete(chantsTable)..where((t) => t.id.equals(id))).go();

  /// Rechercher des chants
  Future<List<ChantsTableData>> searchChants(String query) {
    return (select(chantsTable)
          ..where((t) =>
              t.titre.contains(query) |
              t.auteur.contains(query) |
              t.categorie.contains(query)))
        .get();
  }

  /// Filtrer les chants par catégorie
  Future<List<ChantsTableData>> getChantsByCategory(String category) {
    return (select(chantsTable)..where((t) => t.categorie.equals(category)))
        .get();
  }

  /// Filtrer les chants par type
  Future<List<ChantsTableData>> getChantsByType(String type) {
    return (select(chantsTable)..where((t) => t.type.equals(type))).get();
  }

  // ==================== FAVORIS ====================

  /// Récupérer les favoris d'un utilisateur
  Future<List<FavoritesTableData>> getUserFavorites(String userId) {
    return (select(favoritesTable)..where((t) => t.userId.equals(userId)))
        .get();
  }

  /// Ajouter un favori
  Future<void> addFavorite(FavoritesTableCompanion favorite) =>
      into(favoritesTable).insert(favorite);

  /// Supprimer un favori
  Future<void> removeFavorite(String userId, String chantId) {
    return (delete(favoritesTable)
          ..where((t) => t.userId.equals(userId) & t.chantId.equals(chantId)))
        .go();
  }

  /// Vérifier si un chant est favori
  Future<bool> isFavorite(String userId, String chantId) async {
    final result = await (select(favoritesTable)
          ..where((t) => t.userId.equals(userId) & t.chantId.equals(chantId)))
        .getSingleOrNull();
    return result != null;
  }

  // ==================== PLAYLISTS ====================

  /// Récupérer les playlists d'un utilisateur
  Future<List<PlaylistsTableData>> getUserPlaylists(String userId) {
    return (select(playlistsTable)..where((t) => t.userId.equals(userId)))
        .get();
  }

  /// Créer une playlist
  Future<void> createPlaylist(PlaylistsTableCompanion playlist) =>
      into(playlistsTable).insert(playlist);

  /// Mettre à jour une playlist
  Future<void> updatePlaylist(PlaylistsTableCompanion playlist) =>
      update(playlistsTable).replace(playlist);

  /// Supprimer une playlist
  Future<void> deletePlaylist(String id) =>
      (delete(playlistsTable)..where((t) => t.id.equals(id))).go();

  /// Ajouter un chant à une playlist
  Future<void> addChantToPlaylist(PlaylistChantsTableCompanion playlistChant) =>
      into(playlistChantsTable).insert(playlistChant);

  /// Retirer un chant d'une playlist
  Future<void> removeChantFromPlaylist(String playlistId, String chantId) {
    return (delete(playlistChantsTable)
          ..where((t) =>
              t.playlistId.equals(playlistId) & t.chantId.equals(chantId)))
        .go();
  }

  /// Récupérer les chants d'une playlist
  Future<List<PlaylistChantsTableData>> getPlaylistChants(String playlistId) {
    return (select(playlistChantsTable)
          ..where((t) => t.playlistId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  // ==================== HISTORIQUE ====================

  /// Ajouter une entrée à l'historique
  Future<void> addToHistory(ListeningHistoryTableCompanion history) =>
      into(listeningHistoryTable).insert(history);

  /// Récupérer l'historique d'un utilisateur
  Future<List<ListeningHistoryTableData>> getUserHistory(String userId,
      {int limit = 50}) {
    return (select(listeningHistoryTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.listenedAt)])
          ..limit(limit))
        .get();
  }

  // ==================== TÉLÉCHARGEMENTS ====================

  /// Ajouter un téléchargement
  Future<void> addDownload(DownloadedChantsTableCompanion download) =>
      into(downloadedChantsTable).insert(download);

  /// Récupérer tous les téléchargements
  Future<List<DownloadedChantsTableData>> getAllDownloads() =>
      select(downloadedChantsTable).get();

  /// Supprimer un téléchargement
  Future<void> deleteDownload(String chantId) =>
      (delete(downloadedChantsTable)..where((t) => t.chantId.equals(chantId)))
          .go();

  /// Vérifier si un chant est téléchargé
  Future<bool> isDownloaded(String chantId) async {
    final result = await (select(downloadedChantsTable)
          ..where((t) => t.chantId.equals(chantId)))
        .getSingleOrNull();
    return result != null && result.status == 'completed';
  }

  // ==================== NETTOYAGE ====================

  /// Vider toutes les tables
  Future<void> clearAllData() async {
    await delete(chantsTable).go();
    await delete(favoritesTable).go();
    await delete(playlistsTable).go();
    await delete(playlistChantsTable).go();
    await delete(listeningHistoryTable).go();
    await delete(downloadedChantsTable).go();
  }

  /// Vider les données d'un utilisateur spécifique
  Future<void> clearUserData(String userId) async {
    await (delete(favoritesTable)..where((t) => t.userId.equals(userId))).go();
    await (delete(playlistsTable)..where((t) => t.userId.equals(userId))).go();
    await (delete(listeningHistoryTable)..where((t) => t.userId.equals(userId)))
        .go();
  }
}

/// Fonction pour ouvrir la connexion à la base de données
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chorale_app.db'));
    return NativeDatabase(file);
  });
}
