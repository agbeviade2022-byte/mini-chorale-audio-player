# 🔐 Votre compte Super Admin

## ✅ Configuration effectuée

### Email super admin
**kodjodavid2025@gmail.com**

### Rôle
**super_admin** (accès total)

---

## 🚀 Finaliser la création

### Étape 1: Exécuter le script

**Fichier:** `create_super_admin.sql`

**Instructions:**

1. Aller sur https://app.supabase.com
2. SQL Editor
3. Copier **TOUT** le contenu de `create_super_admin.sql`
4. Coller et **Run**

**Résultat attendu:**

```
🔍 VOTRE USER ID
user_id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
email: kodjodavid2025@gmail.com

✅ SUPER ADMIN CRÉÉ
email: kodjodavid2025@gmail.com
role: super_admin
nb_permissions: 21

📋 PERMISSIONS DU SUPER ADMIN
(Liste de 21 permissions)

🧪 TEST is_system_admin()
est_admin: true

🧪 TEST has_permission()
peut_supprimer_chorales: true
peut_bannir_users: true
peut_modifier_settings: true
```

---

## 💻 Utiliser dans Flutter

### 1. Créer le service admin

Créez `lib/services/admin_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Vérifier si l'utilisateur connecté est admin système
  Future<bool> isSystemAdmin() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final result = await _supabase.rpc(
        'is_system_admin',
        params: {'check_user_id': userId},
      );
      return result as bool;
    } catch (e) {
      print('❌ Erreur is_system_admin: $e');
      return false;
    }
  }

  // Vérifier une permission spécifique
  Future<bool> hasPermission(String permission) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final result = await _supabase.rpc(
        'has_permission',
        params: {
          'check_user_id': userId,
          'permission_name': permission,
        },
      );
      return result as bool;
    } catch (e) {
      print('❌ Erreur has_permission: $e');
      return false;
    }
  }

  // Logger une action admin
  Future<void> logAction({
    required String action,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? details,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.rpc(
        'log_admin_action',
        params: {
          'p_user_id': userId,
          'p_action': action,
          'p_table_name': tableName,
          'p_record_id': recordId,
          'p_details': details,
        },
      );
    } catch (e) {
      print('❌ Erreur log_admin_action: $e');
    }
  }

  // Récupérer toutes les chorales (admin)
  Future<List<Map<String, dynamic>>> getAllChorales() async {
    final result = await _supabase
        .from('chorales')
        .select('*, plans(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  // Supprimer une chorale (avec vérification et log)
  Future<void> deleteChorale(String choraleId) async {
    final canDelete = await hasPermission('chorales.delete');
    if (!canDelete) {
      throw Exception('Permission refusée');
    }

    await _supabase.from('chorales').delete().eq('id', choraleId);

    await logAction(
      action: 'DELETE_CHORALE',
      tableName: 'chorales',
      recordId: choraleId,
    );
  }

  // Suspendre une chorale
  Future<void> suspendChorale(String choraleId) async {
    final canSuspend = await hasPermission('chorales.suspend');
    if (!canSuspend) {
      throw Exception('Permission refusée');
    }

    await _supabase
        .from('chorales')
        .update({'statut': 'suspendu'})
        .eq('id', choraleId);

    await logAction(
      action: 'SUSPEND_CHORALE',
      tableName: 'chorales',
      recordId: choraleId,
    );
  }

  // Récupérer les logs admin
  Future<List<Map<String, dynamic>>> getAdminLogs({int limit = 100}) async {
    final result = await _supabase
        .from('admin_logs')
        .select('*, system_admins(email)')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(result);
  }
}
```

### 2. Créer le provider

Créez `lib/providers/admin_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/admin_service.dart';

// Provider du service admin
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

// Provider pour vérifier si l'utilisateur est admin
final isSystemAdminProvider = FutureProvider<bool>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.isSystemAdmin();
});

// Provider pour récupérer toutes les chorales
final allChoralesAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getAllChorales();
});

// Provider pour les logs admin
final adminLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getAdminLogs();
});
```

### 3. Créer l'écran admin

Créez `lib/screens/admin/admin_dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isSystemAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.red,
      ),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (!isAdmin) {
            return const Center(
              child: Text(
                '❌ Accès refusé\nVous n\'êtes pas administrateur système',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                _buildStatsCards(),
                const SizedBox(height: 24),

                // Chorales
                _buildChoralesSection(ref),
                const SizedBox(height: 24),

                // Logs
                _buildLogsSection(ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Icon(Icons.group, size: 40, color: Colors.blue),
                  SizedBox(height: 8),
                  Text('Chorales', style: TextStyle(fontSize: 16)),
                  Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Icon(Icons.people, size: 40, color: Colors.green),
                  SizedBox(height: 8),
                  Text('Utilisateurs', style: TextStyle(fontSize: 16)),
                  Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoralesSection(WidgetRef ref) {
    final choralesAsync = ref.watch(allChoralesAdminProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎵 Toutes les chorales',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        choralesAsync.when(
          data: (chorales) {
            if (chorales.isEmpty) {
              return const Text('Aucune chorale');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chorales.length,
              itemBuilder: (context, index) {
                final chorale = chorales[index];
                return Card(
                  child: ListTile(
                    title: Text(chorale['nom']),
                    subtitle: Text('Statut: ${chorale['statut']}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Text('Suspendre'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                      onSelected: (value) async {
                        final adminService = ref.read(adminServiceProvider);
                        if (value == 'suspend') {
                          await adminService.suspendChorale(chorale['id']);
                          ref.invalidate(allChoralesAdminProvider);
                        } else if (value == 'delete') {
                          await adminService.deleteChorale(chorale['id']);
                          ref.invalidate(allChoralesAdminProvider);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Erreur: $error'),
        ),
      ],
    );
  }

  Widget _buildLogsSection(WidgetRef ref) {
    final logsAsync = ref.watch(adminLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Logs récents',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Text('Aucun log');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 10 ? 10 : logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(log['action']),
                  subtitle: Text(log['table_name'] ?? ''),
                  trailing: Text(
                    _formatDate(log['created_at']),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Erreur: $error'),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month} ${date.hour}:${date.minute}';
  }
}
```

### 4. Ajouter le bouton admin dans votre app

Dans votre `HomeScreen` ou menu principal:

```dart
// Vérifier si l'utilisateur est admin
final isAdminAsync = ref.watch(isSystemAdminProvider);

isAdminAsync.whenData((isAdmin) {
  if (isAdmin) {
    // Afficher le bouton admin
    FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      },
      child: const Icon(Icons.admin_panel_settings),
      backgroundColor: Colors.red,
    );
  }
});
```

---

## 🎯 Résumé

Après avoir exécuté `create_super_admin.sql`:

- ✅ **Votre compte** kodjodavid2025@gmail.com est super admin
- ✅ **21 permissions** ajoutées
- ✅ **Accès total** à toute la plateforme
- ✅ **Fonctions SQL** prêtes à utiliser
- ✅ **Code Flutter** fourni

**Vous pouvez maintenant gérer toute la plateforme !** 🚀

---

## 📚 Fichiers

1. **`create_super_admin.sql`** ← **EXÉCUTER CE FICHIER** 🎯
2. **`VOTRE_COMPTE_ADMIN.md`** - Ce guide
3. **`ADMIN_SYSTEM_GUIDE.md`** - Documentation complète

**Exécutez `create_super_admin.sql` pour finaliser !** ✅
