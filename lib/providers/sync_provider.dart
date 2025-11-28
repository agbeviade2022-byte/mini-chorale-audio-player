import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/sync_service.dart';
import 'package:mini_chorale_audio_player/providers/storage_providers.dart';

/// Provider pour le service de synchronisation
final syncServiceProvider = Provider<SyncService>((ref) {
  final hiveSession = ref.watch(hiveSessionServiceProvider);
  return SyncService(hiveSession);
});

/// Provider pour l'état de synchronisation
final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncStateNotifier(syncService);
});

/// État de synchronisation
class SyncState {
  final bool isActive;
  final bool isProfileSynced;
  final bool isChoralesSynced;
  final bool isChantsSynced;
  final DateTime? lastSyncAt;
  final String? error;

  SyncState({
    this.isActive = false,
    this.isProfileSynced = false,
    this.isChoralesSynced = false,
    this.isChantsSynced = false,
    this.lastSyncAt,
    this.error,
  });

  SyncState copyWith({
    bool? isActive,
    bool? isProfileSynced,
    bool? isChoralesSynced,
    bool? isChantsSynced,
    DateTime? lastSyncAt,
    String? error,
  }) {
    return SyncState(
      isActive: isActive ?? this.isActive,
      isProfileSynced: isProfileSynced ?? this.isProfileSynced,
      isChoralesSynced: isChoralesSynced ?? this.isChoralesSynced,
      isChantsSynced: isChantsSynced ?? this.isChantsSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error,
    );
  }

  bool get isFullySynced => isProfileSynced && isChoralesSynced && isChantsSynced;
}

/// Notifier pour gérer l'état de synchronisation
class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncStateNotifier(this._syncService) : super(SyncState()) {
    _init();
  }

  void _init() {
    // Écouter les changements de profil
    _syncService.profileChanges.listen((_) {
      state = state.copyWith(
        isProfileSynced: true,
        lastSyncAt: DateTime.now(),
      );
    });

    // Écouter les changements de chorales
    _syncService.choralesChanges.listen((_) {
      state = state.copyWith(
        isChoralesSynced: true,
        lastSyncAt: DateTime.now(),
      );
    });

    // Écouter les changements de chants
    _syncService.chantsChanges.listen((_) {
      state = state.copyWith(
        isChantsSynced: true,
        lastSyncAt: DateTime.now(),
      );
    });
  }

  /// Démarrer la synchronisation
  Future<void> startSync() async {
    try {
      await _syncService.startSync();
      state = state.copyWith(
        isActive: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  /// Arrêter la synchronisation
  Future<void> stopSync() async {
    await _syncService.stopSync();
    state = state.copyWith(
      isActive: false,
    );
  }

  /// Synchroniser manuellement
  Future<void> syncAll() async {
    try {
      await Future.wait([
        _syncService.syncProfile(),
        _syncService.syncChorales(),
        _syncService.syncChants(),
      ]);

      state = state.copyWith(
        isProfileSynced: true,
        isChoralesSynced: true,
        isChantsSynced: true,
        lastSyncAt: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  /// Vérifier la cohérence
  Future<bool> checkConsistency() async {
    return await _syncService.checkConsistency();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
