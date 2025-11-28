import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permissions_provider_riverpod.dart';

/// Widget qui affiche son enfant seulement si l'utilisateur a la permission
class PermissionGuard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    if (permissionsState.hasPermission(permissionCode)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant si l'utilisateur a AU MOINS UNE des permissions
class PermissionGuardAny extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    if (permissionsState.hasAnyPermission(permissionCodes)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant seulement pour les Super Admins
class SuperAdminGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SuperAdminGuard({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    if (permissionsState.isSuperAdmin) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant seulement pour les Admins (admin + super_admin)
class AdminGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminGuard({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    if (permissionsState.isAdmin) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
