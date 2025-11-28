# 🔐 Guide du système d'administration

## 📋 Vue d'ensemble

Le système d'administration permet de gérer toute la plateforme avec 3 niveaux:

### Niveaux d'accès

```
┌─────────────────────────────────────────┐
│         SUPER ADMIN                     │
│  (Accès total à tout le système)       │
├─────────────────────────────────────────┤
│         ADMIN SYSTÈME                   │
│  (Permissions spécifiques)              │
├─────────────────────────────────────────┤
│         ADMIN DE CHORALE                │
│  (Gestion de sa chorale uniquement)     │
├─────────────────────────────────────────┤
│         MEMBRE                          │
│  (Accès basique)                        │
└─────────────────────────────────────────┘
```

## 🗄️ Tables créées

### 1. `system_admins`
Stocke les administrateurs système

**Colonnes:**
- `id` - ID unique
- `user_id` - Référence à auth.users
- `email` - Email de l'admin
- `role` - super_admin | admin | support
- `permissions` - Permissions JSON
- `actif` - Actif ou non
- `created_at` - Date de création

### 2. `admin_logs`
Logs de toutes les actions admin

**Colonnes:**
- `id` - ID unique
- `admin_id` - Qui a fait l'action
- `action` - Type d'action (DELETE_CHORALE, etc.)
- `table_name` - Table concernée
- `record_id` - ID de l'enregistrement
- `details` - Détails JSON
- `ip_address` - IP de l'admin
- `created_at` - Quand

### 3. `permissions`
Liste des permissions disponibles

**Exemples:**
- `chorales.view` - Voir toutes les chorales
- `chorales.delete` - Supprimer des chorales
- `users.ban` - Bannir des utilisateurs
- `system.settings` - Modifier les paramètres

### 4. `admin_permissions`
Liaison entre admins et permissions

---

## 🚀 Installation

### Étape 1: Créer le système d'administration

**Fichier:** `create_admin_system.sql`

```bash
# Dans Supabase SQL Editor
1. Copier tout le contenu de create_admin_system.sql
2. Coller et Run
```

**Résultat attendu:**
- ✅ 4 tables créées
- ✅ 21 permissions créées
- ✅ 3 fonctions créées
- ✅ 1 vue créée

### Étape 2: Créer votre compte super admin

**D'abord, obtenir votre user_id:**

```sql
SELECT id, email FROM auth.users WHERE email = 'votre_email@example.com';
```

**Ensuite, créer le super admin:**

```sql
INSERT INTO system_admins (user_id, email, role)
VALUES (
    'VOTRE_USER_ID'::uuid,
    'votre_email@example.com',
    'super_admin'
);
```

**Vérifier:**

```sql
SELECT * FROM v_system_admins;
```

---

## 💻 Utilisation dans Flutter

### 1. Vérifier si l'utilisateur est admin système

```dart
// Dans votre service Supabase
Future<bool> isSystemAdmin(String userId) async {
  final result = await supabase
      .rpc('is_system_admin', params: {'check_user_id': userId});
  return result as bool;
}
```

### 2. Vérifier une permission spécifique

```dart
Future<bool> hasPermission(String userId, String permission) async {
  final result = await supabase.rpc('has_permission', params: {
    'check_user_id': userId,
    'permission_name': permission,
  });
  return result as bool;
}
```

### 3. Logger une action admin

```dart
Future<void> logAdminAction({
  required String userId,
  required String action,
  String? tableName,
  String? recordId,
  Map<String, dynamic>? details,
}) async {
  await supabase.rpc('log_admin_action', params: {
    'p_user_id': userId,
    'p_action': action,
    'p_table_name': tableName,
    'p_record_id': recordId,
    'p_details': details,
  });
}
```

### 4. Exemple d'utilisation complète

```dart
class AdminService {
  final SupabaseClient supabase;
  
  AdminService(this.supabase);
  
  // Vérifier si admin
  Future<bool> isSystemAdmin(String userId) async {
    final result = await supabase
        .rpc('is_system_admin', params: {'check_user_id': userId});
    return result as bool;
  }
  
  // Supprimer une chorale (avec vérification et log)
  Future<void> deleteChorale(String userId, String choraleId) async {
    // 1. Vérifier la permission
    final canDelete = await supabase.rpc('has_permission', params: {
      'check_user_id': userId,
      'permission_name': 'chorales.delete',
    });
    
    if (!canDelete) {
      throw Exception('Permission refusée');
    }
    
    // 2. Supprimer la chorale
    await supabase.from('chorales').delete().eq('id', choraleId);
    
    // 3. Logger l'action
    await supabase.rpc('log_admin_action', params: {
      'p_user_id': userId,
      'p_action': 'DELETE_CHORALE',
      'p_table_name': 'chorales',
      'p_record_id': choraleId,
      'p_details': {'reason': 'Violation des conditions'},
    });
  }
  
  // Récupérer tous les admins
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    final result = await supabase.from('v_system_admins').select();
    return List<Map<String, dynamic>>.from(result);
  }
  
  // Récupérer les logs d'un admin
  Future<List<Map<String, dynamic>>> getAdminLogs(String adminId) async {
    final result = await supabase
        .from('admin_logs')
        .select()
        .eq('admin_id', adminId)
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(result);
  }
}
```

---

## 🎯 Cas d'usage

### Cas 1: Dashboard admin système

```dart
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ref.read(adminServiceProvider).isSystemAdmin(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return Text('Accès refusé');
        }
        
        return Column(
          children: [
            AdminStatsCard(),
            ChoralesListAdmin(),
            UsersListAdmin(),
            SystemLogsAdmin(),
          ],
        );
      },
    );
  }
}
```

### Cas 2: Bouton de suppression avec permission

```dart
IconButton(
  icon: Icon(Icons.delete),
  onPressed: () async {
    final canDelete = await adminService.hasPermission(
      currentUserId,
      'chorales.delete',
    );
    
    if (!canDelete) {
      showSnackBar('Permission refusée');
      return;
    }
    
    await adminService.deleteChorale(currentUserId, choraleId);
    showSnackBar('Chorale supprimée');
  },
)
```

### Cas 3: Afficher les logs admin

```dart
class AdminLogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: adminService.getAdminLogs(adminId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final log = snapshot.data![index];
            return ListTile(
              title: Text(log['action']),
              subtitle: Text(log['table_name'] ?? ''),
              trailing: Text(
                formatDate(log['created_at']),
              ),
            );
          },
        );
      },
    );
  }
}
```

---

## 📊 Permissions disponibles

### Chorales
- `chorales.view` - Voir toutes les chorales
- `chorales.create` - Créer des chorales
- `chorales.edit` - Modifier des chorales
- `chorales.delete` - Supprimer des chorales
- `chorales.suspend` - Suspendre des chorales

### Utilisateurs
- `users.view` - Voir tous les utilisateurs
- `users.edit` - Modifier des utilisateurs
- `users.delete` - Supprimer des utilisateurs
- `users.ban` - Bannir des utilisateurs

### Plans
- `plans.view` - Voir les plans
- `plans.create` - Créer des plans
- `plans.edit` - Modifier des plans
- `plans.delete` - Supprimer des plans

### Chants
- `chants.view_all` - Voir tous les chants
- `chants.edit_all` - Modifier tous les chants
- `chants.delete_all` - Supprimer tous les chants

### Système
- `system.logs` - Voir les logs système
- `system.settings` - Modifier les paramètres
- `system.backup` - Gérer les sauvegardes

### Support
- `support.tickets` - Gérer les tickets
- `support.chat` - Accès au chat support

---

## 🔒 Sécurité

### Bonnes pratiques

1. **Super admin unique** - Un seul super admin par plateforme
2. **Permissions granulaires** - Donner uniquement les permissions nécessaires
3. **Logs obligatoires** - Toujours logger les actions sensibles
4. **Vérification côté serveur** - Ne jamais se fier au client

### Exemple de vérification sécurisée

```dart
// ❌ MAUVAIS (vérification côté client uniquement)
if (user.role == 'admin') {
  await deleteChorale(choraleId);
}

// ✅ BON (vérification côté serveur)
Future<void> deleteChorale(String choraleId) async {
  // La fonction RPC vérifie la permission côté serveur
  final canDelete = await supabase.rpc('has_permission', params: {
    'check_user_id': currentUserId,
    'permission_name': 'chorales.delete',
  });
  
  if (!canDelete) throw Exception('Permission refusée');
  
  await supabase.from('chorales').delete().eq('id', choraleId);
}
```

---

## 📚 Requêtes utiles

### Voir tous les admins

```sql
SELECT * FROM v_system_admins;
```

### Voir les logs récents

```sql
SELECT 
    sa.email,
    al.action,
    al.table_name,
    al.created_at
FROM admin_logs al
JOIN system_admins sa ON al.admin_id = sa.id
ORDER BY al.created_at DESC
LIMIT 50;
```

### Ajouter une permission à un admin

```sql
INSERT INTO admin_permissions (admin_id, permission_id)
SELECT 
    sa.id,
    p.id
FROM system_admins sa, permissions p
WHERE sa.email = 'admin@example.com'
AND p.nom = 'chorales.delete';
```

---

## 🎉 Résumé

Après installation du système d'administration:

- ✅ **4 tables** pour gérer les admins
- ✅ **21 permissions** prédéfinies
- ✅ **3 fonctions** SQL pour vérifier les droits
- ✅ **1 vue** pour faciliter la gestion
- ✅ **Logs automatiques** de toutes les actions
- ✅ **Système de permissions granulaire**

**Votre plateforme est maintenant prête pour une gestion professionnelle !** 🚀
