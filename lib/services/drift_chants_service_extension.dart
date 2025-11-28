import 'package:flutter/foundation.dart';
import 'drift_chants_service.dart';

/// Extension pour ajouter des méthodes de nettoyage à DriftChantsService
extension DriftChantsServiceCleaning on DriftChantsService {
  /// Effacer TOUTES les données de la base de données Drift
  Future<void> clearAllData() async {
    try {
      debugPrint('🧹 Nettoyage de la base de données Drift...');

      // Effacer toutes les tables
      await database.delete(database.chantsTable).go();
      debugPrint('  ✅ Table chants effacée');

      await database.delete(database.favoritesTable).go();
      debugPrint('  ✅ Table favoris effacée');

      await database.delete(database.playlistsTable).go();
      debugPrint('  ✅ Table playlists effacée');

      await database.delete(database.playlistChantsTable).go();
      debugPrint('  ✅ Table playlist_chants effacée');

      await database.delete(database.listeningHistoryTable).go();
      debugPrint('  ✅ Table historique effacée');

      await database.delete(database.downloadedChantsTable).go();
      debugPrint('  ✅ Table téléchargements effacée');

      debugPrint('✅ Base de données Drift complètement nettoyée');
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage Drift: $e');
      rethrow;
    }
  }
}
