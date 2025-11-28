# 🔄 INTÉGRATION RIVERPOD - SYSTÈME DE PERMISSIONS

## ✅ FICHIERS CRÉÉS POUR RIVERPOD

1. **`lib/providers/permissions_provider_riverpod.dart`**
   - `PermissionsState` - État des permissions
   - `PermissionsNotifier` - Notifier pour gérer l'état
   - `permissionsProvider` - Provider Riverpod

2. **`lib/widgets/permission_guard_riverpod.dart`**
   - `PermissionGuard` - Widget conditionnel
   - `PermissionGuardAny` - Au moins une permission
   - `SuperAdminGuard` - Super admin only
   - `AdminGuard` - Admin + Super admin

---

## 📝 ÉTAPE 1: Charger les permissions après connexion

**Fichier à modifier:** Votre service d'authentification (probablement dans `lib/services/`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permissions_provider_riverpod.dart';

// Dans votre fonction de connexion
Future<void> signIn(String email, String password, WidgetRef ref) async {
  try {
    // Votre code de connexion existant
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // ⚠️ AJOUTER: Charger les permissions après connexion
    await ref.read(permissionsProvider.notifier).loadUserPermissions();
    
    print('✅ Permissions chargées après connexion');
  } catch (e) {
    print('❌ Erreur connexion: $e');
    rethrow;
  }
}

// Dans votre fonction de déconnexion
Future<void> signOut(WidgetRef ref) async {
  try {
    await supabase.auth.signOut();
    
    // ⚠️ AJOUTER: Réinitialiser les permissions
    ref.read(permissionsProvider.notifier).clear();
    
    print('✅ Permissions réinitialisées après déconnexion');
  } catch (e) {
    print('❌ Erreur déconnexion: $e');
    rethrow;
  }
}
```

---

## 📝 ÉTAPE 2: Utiliser dans les widgets

### **Exemple 1: HomeScreen avec Drawer**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/permission_guard_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Menu'),
            ),
            
            // Visible seulement si permission 'view_dashboard'
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
            
            // Visible seulement pour Super Admin
            SuperAdminGuard(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Créer Maître de Chœur'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/create-mc');
                },
              ),
            ),
            
            // Visible si permission 'view_members'
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
          ],
        ),
      ),
      
      // FloatingActionButton conditionnel
      floatingActionButton: PermissionGuard(
        permissionCode: 'add_chants',
        child: FloatingActionButton(
          onPressed: () {
            // Ajouter un chant
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

---

### **Exemple 2: Écran Admin protégé**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/permission_guard_riverpod.dart';
import '../providers/permissions_provider_riverpod.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    // Afficher un loader pendant le chargement
    if (permissionsState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Vérifier l'accès
    if (!permissionsState.hasPermission('view_dashboard')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Text('Vous n\'avez pas accès à cette page'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          // Badge du rôle
          Chip(
            label: Text(permissionsState.role ?? 'Membre'),
            backgroundColor: permissionsState.isSuperAdmin
                ? Colors.red
                : Colors.blue,
          ),
        ],
      ),
      body: Column(
        children: [
          // Section visible seulement pour Super Admin
          SuperAdminGuard(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Gestion des Maîtres de Chœur'),
                subtitle: Text(
                  '${permissionsState.permissions.length} permissions actives',
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/maitres-choeur');
                },
              ),
            ),
          ),
          
          // Section visible pour Admin et Super Admin
          AdminGuard(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Validation des Membres'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/validate-members');
                },
              ),
            ),
          ),
          
          // Section visible si permission 'view_stats'
          PermissionGuard(
            permissionCode: 'view_stats',
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Statistiques'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/stats');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### **Exemple 3: Vérifier les permissions dans le code**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permissions_provider_riverpod.dart';

class ChantsListScreen extends ConsumerWidget {
  const ChantsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chants')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Chant $index'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton modifier visible si permission 'edit_chants'
                if (permissionsState.hasPermission('edit_chants'))
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Modifier le chant
                    },
                  ),
                
                // Bouton supprimer visible si permission 'delete_chants'
                if (permissionsState.hasPermission('delete_chants'))
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Supprimer le chant
                    },
                  ),
              ],
            ),
          );
        },
      ),
      
      // FAB visible si permission 'add_chants'
      floatingActionButton: permissionsState.hasPermission('add_chants')
          ? FloatingActionButton(
              onPressed: () {
                // Ajouter un chant
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
```

---

## 📝 ÉTAPE 3: Charger les permissions au démarrage (Optionnel)

**Fichier:** `lib/screens/splash/splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/permissions_provider_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session != null) {
        // Utilisateur connecté, charger les permissions
        await ref.read(permissionsProvider.notifier).loadUserPermissions();
        
        // Naviguer vers la home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Pas connecté, aller au login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('❌ Erreur vérification auth: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

## 🧪 TESTS

### **Test 1: Vérifier le chargement des permissions**

```dart
// Dans votre écran de test
final permissionsState = ref.watch(permissionsProvider);

print('Rôle: ${permissionsState.role}');
print('Permissions: ${permissionsState.permissions}');
print('Est Super Admin: ${permissionsState.isSuperAdmin}');
print('Est Admin: ${permissionsState.isAdmin}');
```

### **Test 2: Rafraîchir les permissions**

```dart
// Bouton pour rafraîchir
ElevatedButton(
  onPressed: () async {
    await ref.read(permissionsProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permissions rafraîchies')),
    );
  },
  child: const Text('Rafraîchir permissions'),
)
```

---

## 📋 CHECKLIST D'INTÉGRATION

- [ ] Fichiers Riverpod créés (`permissions_provider_riverpod.dart`, `permission_guard_riverpod.dart`)
- [ ] Charger permissions après connexion
- [ ] Réinitialiser permissions après déconnexion
- [ ] Protéger écrans admin avec `PermissionGuard`
- [ ] Protéger boutons avec `PermissionGuard`
- [ ] Tester avec Super Admin
- [ ] Tester avec Maître de Chœur
- [ ] Tester avec Membre

---

## 🎯 RÉSUMÉ

**Fichiers créés:**
- ✅ `permissions_provider_riverpod.dart` - Provider Riverpod
- ✅ `permission_guard_riverpod.dart` - Widgets Riverpod

**À faire:**
1. Charger permissions après connexion
2. Utiliser `PermissionGuard` dans vos écrans
3. Tester le système

**Temps estimé:** 15 minutes

---

**Le système est prêt pour Riverpod ! 🚀**
