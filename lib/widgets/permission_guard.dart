import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permissions_provider.dart';

/// Widget qui affiche son enfant seulement si l'utilisateur a la permission
class PermissionGuard extends StatelessWidget {
  final String permissionCode;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    Key? key,
    required this.permissionCode,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionsProvider = Provider.of<PermissionsProvider>(context);

    if (permissionsProvider.hasPermission(permissionCode)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant si l'utilisateur a AU MOINS UNE des permissions
class PermissionGuardAny extends StatelessWidget {
  final List<String> permissionCodes;
  final Widget child;
  final Widget? fallback;

  const PermissionGuardAny({
    Key? key,
    required this.permissionCodes,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionsProvider = Provider.of<PermissionsProvider>(context);

    if (permissionsProvider.hasAnyPermission(permissionCodes)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant seulement pour les Super Admins
class SuperAdminGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const SuperAdminGuard({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionsProvider = Provider.of<PermissionsProvider>(context);

    if (permissionsProvider.isSuperAdmin) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant seulement pour les Admins (admin + super_admin)
class AdminGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminGuard({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionsProvider = Provider.of<PermissionsProvider>(context);

    if (permissionsProvider.isAdmin) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
