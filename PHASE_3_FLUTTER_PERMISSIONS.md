# 🚀 PHASE 3: IMPLÉMENTATION FLUTTER - SYSTÈME DE PERMISSIONS MODULAIRES

## 📋 OBJECTIF

Intégrer le système de permissions modulaires dans l'application Flutter pour:
1. Vérifier les permissions de l'utilisateur connecté
2. Afficher/masquer les fonctionnalités selon les permissions
3. Gérer l'interface admin modulaire

---

## 🗂️ FICHIERS À CRÉER/MODIFIER

### **1. Service de Permissions**
- `lib/services/permissions_service.dart`

### **2. Provider de Permissions**
- `lib/providers/permissions_provider.dart`

### **3. Widgets de Permissions**
- `lib/widgets/permission_guard.dart`
- `lib/widgets/permission_button.dart`

### **4. Écrans Admin**
- `lib/screens/admin/admin_dashboard_screen.dart` (modifier)
- `lib/screens/admin/manage_permissions_screen.dart` (créer)
- `lib/screens/admin/create_maitre_choeur_screen.dart` (créer)

---

## 📝 ÉTAPE 1: Créer le Service de Permissions

**Fichier:** `lib/services/permissions_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PermissionsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupérer toutes les permissions de l'utilisateur connecté
  Future<List<String>> getUserPermissions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Récupérer le profile_id depuis profiles
      final profileResponse = await _supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', userId)
          .single();

      final profileId = profileResponse['id'];
      final role = profileResponse['role'];

      // Super admin a toutes les permissions
      if (role == 'super_admin') {
        final allPermissions = await _supabase
            .from('modules_permissions')
            .select('code');
        return (allPermissions as List)
            .map((p) => p['code'] as String)
            .toList();
      }

      // Appeler la fonction SQL get_user_permissions
      final response = await _supabase
          .rpc('get_user_permissions', params: {'check_user_id': profileId});

      if (response == null) return [];

      // Parser le JSON retourné
      final permissions = response as List;
      return permissions
          .map((p) => p['code'] as String)
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des permissions: $e');
      return [];
    }
  }

  /// Vérifier si l'utilisateur a une permission spécifique
  Future<bool> hasPermission(String permissionCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final profileResponse = await _supabase
          .from('profiles')
          .select('id, role')
          .eq('user_id', userId)
          .single();

      final profileId = profileResponse['id'];
      final role = profileResponse['role'];

      // Super admin a toutes les permissions
      if (role == 'super_admin') return true;

      // Appeler la fonction SQL has_permission
      final response = await _supabase.rpc('has_permission', params: {
        'check_user_id': profileId,
        'permission_code': permissionCode
      });

      return response == true;
    } catch (e) {
      print('Erreur lors de la vérification de permission: $e');
      return false;
    }
  }

  /// Récupérer le rôle de l'utilisateur
  Future<String?> getUserRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .single();

      return response['role'] as String?;
    } catch (e) {
      print('Erreur lors de la récupération du rôle: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est Super Admin
  Future<bool> isSuperAdmin() async {
    final role = await getUserRole();
    return role == 'super_admin';
  }

  /// Vérifier si l'utilisateur est Maître de Chœur
  Future<bool> isMaitreChoeur() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('est_maitre_choeur')
          .eq('user_id', userId)
          .single();

      return response['est_maitre_choeur'] == true;
    } catch (e) {
      print('Erreur lors de la vérification MC: $e');
      return false;
    }
  }

  /// Récupérer tous les modules de permissions disponibles
  Future<List<Map<String, dynamic>>> getAllModules() async {
    try {
      final response = await _supabase
          .from('modules_permissions')
          .select('*')
          .order('ordre');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur lors de la récupération des modules: $e');
      return [];
    }
  }

  /// Attribuer une permission à un utilisateur
  Future<bool> assignPermission({
    required String targetUserId,
    required String permissionCode,
    DateTime? expiresAt,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Récupérer les profile IDs
      final currentProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final targetProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', targetUserId)
          .single();

      // Appeler la fonction SQL
      await _supabase.rpc('attribuer_permission', params: {
        'p_user_id': targetProfile['id'],
        'p_module_code': permissionCode,
        'p_attribue_par': currentProfile['id'],
        'p_expire_le': expiresAt?.toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'attribution de permission: $e');
      return false;
    }
  }

  /// Révoquer une permission
  Future<bool> revokePermission({
    required String targetUserId,
    required String permissionCode,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final currentProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final targetProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', targetUserId)
          .single();

      await _supabase.rpc('revoquer_permission', params: {
        'p_user_id': targetProfile['id'],
        'p_module_code': permissionCode,
        'p_revoque_par': currentProfile['id'],
      });

      return true;
    } catch (e) {
      print('Erreur lors de la révocation de permission: $e');
      return false;
    }
  }
}
```

---

## 📝 ÉTAPE 2: Créer le Provider de Permissions

**Fichier:** `lib/providers/permissions_provider.dart`

```dart
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
```

---

## 📝 ÉTAPE 3: Créer le Widget PermissionGuard

**Fichier:** `lib/widgets/permission_guard.dart`

```dart
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
```

---

## 📝 ÉTAPE 4: Modifier main.dart

**Fichier:** `lib/main.dart`

Ajouter le `PermissionsProvider`:

```dart
import 'package:provider/provider.dart';
import 'providers/permissions_provider.dart';

// Dans le MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => PermissionsProvider()), // ⚠️ AJOUTER
    // ... autres providers
  ],
  child: MyApp(),
)
```

---

## 📝 ÉTAPE 5: Charger les permissions après connexion

**Fichier:** `lib/providers/auth_provider.dart`

Modifier la méthode `signIn`:

```dart
Future<void> signIn(String email, String password) async {
  try {
    await _authService.signIn(email, password);
    
    // ⚠️ AJOUTER: Charger les permissions après connexion
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context, 
      listen: false
    );
    await permissionsProvider.loadUserPermissions();
    
    notifyListeners();
  } catch (e) {
    // ...
  }
}
```

---

## 📝 ÉTAPE 6: Exemple d'utilisation dans HomeScreen

**Fichier:** `lib/screens/home/home_screen.dart`

```dart
import '../../widgets/permission_guard.dart';

// Dans le Drawer ou menu
PermissionGuard(
  permissionCode: 'view_dashboard',
  child: ListTile(
    leading: Icon(Icons.dashboard),
    title: Text('Dashboard Admin'),
    onTap: () {
      Navigator.pushNamed(context, '/admin/dashboard');
    },
  ),
),

SuperAdminGuard(
  child: ListTile(
    leading: Icon(Icons.admin_panel_settings),
    title: Text('Créer Maître de Chœur'),
    onTap: () {
      Navigator.pushNamed(context, '/admin/create-mc');
    },
  ),
),

PermissionGuard(
  permissionCode: 'add_chants',
  child: FloatingActionButton(
    onPressed: () {
      // Ajouter un chant
    },
    child: Icon(Icons.add),
  ),
),
```

---

## 🧪 TESTS À EFFECTUER

### **Test 1: Connexion Super Admin**
```dart
// Se connecter avec kodjodavid2025@gmail.com
// Vérifier que TOUTES les fonctionnalités sont visibles
```

### **Test 2: Connexion Maître de Chœur**
```dart
// Se connecter avec un MC
// Vérifier que seules les permissions MC sont visibles
// Vérifier que "Créer MC" n'est PAS visible
```

### **Test 3: Connexion Membre**
```dart
// Se connecter avec un membre simple
// Vérifier que seules les fonctionnalités de base sont visibles
```

---

## 📋 CHECKLIST PHASE 3

- [ ] Créer `permissions_service.dart`
- [ ] Créer `permissions_provider.dart`
- [ ] Créer `permission_guard.dart`
- [ ] Ajouter `PermissionsProvider` dans `main.dart`
- [ ] Charger les permissions après connexion
- [ ] Protéger les écrans admin avec `PermissionGuard`
- [ ] Protéger les boutons avec `PermissionGuard`
- [ ] Tester avec Super Admin
- [ ] Tester avec Maître de Chœur
- [ ] Tester avec Membre

---

## 🎯 PROCHAINE ÉTAPE APRÈS PHASE 3

**Phase 4:** Implémentation Dashboard Web (React/Next.js)

---

## 📄 FICHIERS CRÉÉS

1. ✅ `PHASE_3_FLUTTER_PERMISSIONS.md` - Ce guide
2. À créer: `permissions_service.dart`
3. À créer: `permissions_provider.dart`
4. À créer: `permission_guard.dart`

---

**Commencez par créer le `PermissionsService` ! 🚀**
