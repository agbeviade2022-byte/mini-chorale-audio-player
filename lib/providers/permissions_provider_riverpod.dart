import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permissions_service.dart';

/// État des permissions
class PermissionsState {
  final List<String> permissions;
  final String? role;
  final bool isLoading;
  final String? error;

  PermissionsState({
    this.permissions = const [],
    this.role,
    this.isLoading = false,
    this.error,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  bool hasPermission(String code) {
    if (isSuperAdmin) return true;
    return permissions.contains(code);
  }

  bool hasAnyPermission(List<String> codes) {
    if (isSuperAdmin) return true;
    return codes.any((code) => permissions.contains(code));
  }

  bool hasAllPermissions(List<String> codes) {
    if (isSuperAdmin) return true;
    return codes.every((code) => permissions.contains(code));
  }

  PermissionsState copyWith({
    List<String>? permissions,
    String? role,
    bool? isLoading,
    String? error,
  }) {
    return PermissionsState(
      permissions: permissions ?? this.permissions,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier pour gérer les permissions
class PermissionsNotifier extends StateNotifier<PermissionsState> {
  final PermissionsService _permissionsService = PermissionsService();

  PermissionsNotifier() : super(PermissionsState());

  /// Charger les permissions de l'utilisateur
  Future<void> loadUserPermissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final permissions = await _permissionsService.getUserPermissions();
      final role = await _permissionsService.getUserRole();

      state = PermissionsState(
        permissions: permissions,
        role: role,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des permissions: $e',
      );
      print(state.error);
    }
  }

  /// Rafraîchir les permissions
  Future<void> refresh() async {
    await loadUserPermissions();
  }

  /// Réinitialiser les permissions (déconnexion)
  void clear() {
    state = PermissionsState();
  }
}

/// Provider pour les permissions
final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});
