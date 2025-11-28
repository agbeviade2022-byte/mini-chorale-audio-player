# 🚀 INTÉGRATION FINALE - SYSTÈME DE PERMISSIONS

## 📝 MODIFICATIONS À FAIRE

### **FICHIER 1: `lib/services/enhanced_auth_service.dart`**

#### **Ajouter l'import en haut du fichier (ligne 11)**

```dart
import 'package:mini_chorale_audio_player/services/permissions_service.dart';
```

#### **Modifier la méthode `signIn` (après la ligne 120)**

**AVANT:**
```dart
      print('✅ Connexion réussie et session sauvegardée de manière sécurisée');
      return response;
```

**APRÈS:**
```dart
      // 7. Charger les permissions de l'utilisateur
      try {
        final permissionsService = PermissionsService();
        final permissions = await permissionsService.getUserPermissions();
        final role = await permissionsService.getUserRole();
        print('✅ Permissions chargées: ${permissions.length} permissions, rôle: $role');
      } catch (e) {
        print('⚠️ Erreur chargement permissions: $e');
        // Ne pas bloquer la connexion si les permissions échouent
      }

      print('✅ Connexion réussie et session sauvegardée de manière sécurisée');
      return response;
```

---

### **FICHIER 2: Créer un Provider pour EnhancedAuthService**

**Nouveau fichier:** `lib/providers/auth_service_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_auth_service.dart';
import '../services/hive_session_service.dart';
import '../services/encrypted_hive_service.dart';
import '../services/session_tracking_service.dart';
import '../services/secure_storage_service.dart';
import 'storage_providers.dart';

/// Provider pour EnhancedAuthService
final enhancedAuthServiceProvider = Provider<EnhancedAuthService>((ref) {
  final hiveSession = ref.watch(hiveSessionServiceProvider);
  
  return EnhancedAuthService(
    hiveSession,
    encryptedHive: EncryptedHiveService(),
    sessionTracking: SessionTrackingService(),
    secureStorage: SecureStorageService(),
  );
});
```

---

### **FICHIER 3: Créer un AuthController pour gérer connexion/déconnexion**

**Nouveau fichier:** `lib/controllers/auth_controller.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_service_provider.dart';
import '../providers/permissions_provider_riverpod.dart';

/// Controller pour gérer l'authentification avec permissions
class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AuthController(this.ref) : super(const AsyncValue.data(null));

  /// Connexion avec chargement des permissions
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      // 1. Connexion via EnhancedAuthService
      final authService = ref.read(enhancedAuthServiceProvider);
      await authService.signIn(email: email, password: password);
      
      // 2. Charger les permissions
      await ref.read(permissionsProvider.notifier).loadUserPermissions();
      
      print('✅ Connexion et permissions chargées avec succès');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('❌ Erreur connexion: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Déconnexion avec nettoyage des permissions
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      // 1. Déconnexion via EnhancedAuthService
      final authService = ref.read(enhancedAuthServiceProvider);
      await authService.signOut();
      
      // 2. Réinitialiser les permissions
      ref.read(permissionsProvider.notifier).clear();
      
      print('✅ Déconnexion et permissions réinitialisées');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('❌ Erreur déconnexion: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Inscription
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final authService = ref.read(enhancedAuthServiceProvider);
      await authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      print('✅ Inscription réussie');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      print('❌ Erreur inscription: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider pour AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
```

---

### **FICHIER 4: Modifier vos écrans de connexion/déconnexion**

#### **Écran de Login (exemple)**

**AVANT:**
```dart
final authService = EnhancedAuthService(...);
await authService.signIn(email: email, password: password);
```

**APRÈS:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);
    
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: authController.isLoading
                ? null
                : () async {
                    try {
                      await ref.read(authControllerProvider.notifier).signIn(
                        email,
                        password,
                      );
                      
                      // Navigation après succès
                      Navigator.pushReplacementNamed(context, '/home');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  },
            child: authController.isLoading
                ? CircularProgressIndicator()
                : Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
```

#### **Bouton de déconnexion (exemple)**

```dart
ElevatedButton(
  onPressed: () async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur déconnexion: $e')),
      );
    }
  },
  child: Text('Déconnexion'),
)
```

---

### **FICHIER 5: Utiliser les permissions dans HomeScreen**

**Fichier:** `lib/screens/home/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/permission_guard_riverpod.dart';
import '../../providers/permissions_provider_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          // Badge du rôle
          if (permissionsState.role != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  permissionsState.role!,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: permissionsState.isSuperAdmin
                    ? Colors.red
                    : permissionsState.isAdmin
                        ? Colors.orange
                        : Colors.blue,
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            
            // Accueil (visible pour tous)
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Accueil'),
              onTap: () => Navigator.pop(context),
            ),
            
            const Divider(),
            
            // Dashboard Admin (permission requise)
            PermissionGuard(
              permissionCode: 'view_dashboard',
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard Admin'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/dashboard');
                },
              ),
            ),
            
            // Gestion Membres (permission requise)
            PermissionGuard(
              permissionCode: 'view_members',
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Gestion Membres'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/members');
                },
              ),
            ),
            
            // Créer Maître de Chœur (Super Admin only)
            SuperAdminGuard(
              child: Column(
                children: [
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Créer Maître de Chœur'),
                    tileColor: Colors.red.withOpacity(0.1),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/create-mc');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // FAB conditionnel
      floatingActionButton: PermissionGuard(
        permissionCode: 'add_chants',
        child: FloatingActionButton(
          onPressed: () {
            // Ajouter un chant
            Navigator.pushNamed(context, '/chants/add');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

---

## 📋 CHECKLIST D'INTÉGRATION

- [ ] Ajouter import `permissions_service.dart` dans `enhanced_auth_service.dart`
- [ ] Modifier méthode `signIn` pour charger permissions
- [ ] Créer `auth_service_provider.dart`
- [ ] Créer `auth_controller.dart`
- [ ] Modifier écrans de login/logout pour utiliser `authControllerProvider`
- [ ] Utiliser `PermissionGuard` dans `HomeScreen`
- [ ] Tester connexion Super Admin
- [ ] Tester connexion Maître de Chœur
- [ ] Tester connexion Membre

---

## 🧪 TESTS

### **Test 1: Connexion Super Admin**
```
Email: kodjodavid2025@gmail.com
Résultat attendu:
- ✅ Connexion réussie
- ✅ Permissions chargées (16 permissions)
- ✅ Rôle: super_admin
- ✅ Toutes les options visibles
```

### **Test 2: Vérifier les permissions dans les logs**
```dart
// Après connexion, vérifier les logs
final permissionsState = ref.read(permissionsProvider);
print('Rôle: ${permissionsState.role}');
print('Permissions: ${permissionsState.permissions}');
print('Est Super Admin: ${permissionsState.isSuperAdmin}');
```

---

## 🎯 RÉSUMÉ

**Fichiers à créer:**
1. ✅ `lib/providers/auth_service_provider.dart`
2. ✅ `lib/controllers/auth_controller.dart`

**Fichiers à modifier:**
1. ✅ `lib/services/enhanced_auth_service.dart` (ajouter chargement permissions)
2. ✅ Vos écrans de login/logout (utiliser authController)
3. ✅ `lib/screens/home/home_screen.dart` (ajouter PermissionGuard)

**Temps estimé:** 20 minutes

---

**Commencez par créer les 2 nouveaux fichiers ! 🚀**
