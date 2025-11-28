import 'package:flutter/foundation.dart';
import '../services/permissions_service.dart';

class PermissionsProvider with ChangeNotifier {
  final PermissionsService _permissionsService = PermissionsService();

  List<String> _userPermissions = [];
  String? _userRole;
  bool _isLoading = false;
  String? _error;

  List<String> get userPermissions => _userPermissions;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isSuperAdmin => _userRole == 'super_admin';
  bool get isAdmin => _userRole == 'admin' || _userRole == 'super_admin';

  /// Charger les permissions de l'utilisateur
  Future<void> loadUserPermissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userPermissions = await _permissionsService.getUserPermissions();
      _userRole = await _permissionsService.getUserRole();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des permissions: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifier si l'utilisateur a une permission
  bool hasPermission(String permissionCode) {
    if (isSuperAdmin) return true;
    return _userPermissions.contains(permissionCode);
  }

  /// Vérifier si l'utilisateur a au moins une des permissions
  bool hasAnyPermission(List<String> permissionCodes) {
    if (isSuperAdmin) return true;
    return permissionCodes.any((code) => _userPermissions.contains(code));
  }

  /// Vérifier si l'utilisateur a toutes les permissions
  bool hasAllPermissions(List<String> permissionCodes) {
    if (isSuperAdmin) return true;
    return permissionCodes.every((code) => _userPermissions.contains(code));
  }

  /// Rafraîchir les permissions
  Future<void> refresh() async {
    await loadUserPermissions();
  }

  /// Réinitialiser les permissions (déconnexion)
  void clear() {
    _userPermissions = [];
    _userRole = null;
    _error = null;
    notifyListeners();
  }
}
