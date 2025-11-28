import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/database/drift_database.dart';
import 'package:mini_chorale_audio_player/services/hive_session_service.dart';
import 'package:mini_chorale_audio_player/services/drift_chants_service.dart';

/// Provider pour la base de données Drift (SQLite)
/// 🥈 Utilisé pour stocker les chants, playlists, historique
final driftDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider pour le service Hive de session
/// 🏆 Utilisé pour garder l'utilisateur connecté et stocker son profil
final hiveSessionServiceProvider = Provider<HiveSessionService>((ref) {
  return HiveSessionService();
});

/// Provider pour le service Drift des chants
/// Combine la base de données avec la logique métier
final driftChantsServiceProvider = Provider<DriftChantsService>((ref) {
  final database = ref.watch(driftDatabaseProvider);
  return DriftChantsService(database);
});

/// Provider pour vérifier si une session existe
final hasSessionProvider = Provider<bool>((ref) {
  final sessionService = ref.watch(hiveSessionServiceProvider);
  return sessionService.hasSession();
});

/// Provider pour vérifier si la session est valide
final isSessionValidProvider = Provider<bool>((ref) {
  final sessionService = ref.watch(hiveSessionServiceProvider);
  return sessionService.isSessionValid();
});

/// Provider pour obtenir la session actuelle
final currentSessionProvider = Provider((ref) {
  final sessionService = ref.watch(hiveSessionServiceProvider);
  return sessionService.getSession();
});

/// Provider pour obtenir les paramètres de l'application
final appSettingsProvider = Provider((ref) {
  final sessionService = ref.watch(hiveSessionServiceProvider);
  return sessionService.getSettings();
});
