# 🚀 GUIDE D'IMPLÉMENTATION: Système de Permissions Modulaires

## 📋 PLAN D'ACTION

### **Phase 1: Backend (Supabase)** ⏱️ 30 min
1. Exécuter la migration SQL
2. Créer un Super Admin
3. Tester les fonctions SQL

### **Phase 2: Flutter (Mobile)** ⏱️ 2-3 heures
1. Créer les providers de permissions
2. Créer les widgets conditionnels
3. Adapter le menu dynamique
4. Créer les écrans de gestion

### **Phase 3: Dashboard Web** ⏱️ 2-3 heures
1. Créer les hooks de permissions
2. Créer les composants conditionnels
3. Adapter la navigation
4. Créer les pages de gestion

### **Phase 4: Tests** ⏱️ 1 heure
1. Tester la création de MC
2. Tester les liens d'affiliation
3. Tester l'attribution de permissions
4. Vérifier l'interface dynamique

---

## 🎯 PHASE 1: BACKEND (SUPABASE)

### **Étape 1.1: Exécuter la migration**

```sql
-- 1. Ouvrir Supabase SQL Editor
-- 2. Copier/coller migration_systeme_permissions_modulaires.sql
-- 3. Exécuter
```

**Résultat attendu:**
```
✅ SYSTÈME DE PERMISSIONS MODULAIRES CRÉÉ
📊 STATISTIQUES:
  - Modules disponibles: 16
  - Permissions attribuées: 0
🔧 FONCTIONS CRÉÉES:
  - creer_maitre_choeur()
  - has_permission()
  - get_user_permissions()
  - attribuer_permission()
  - revoquer_permission()
```

---

### **Étape 1.2: Créer un Super Admin**

```sql
-- Vérifier si vous avez déjà un SA
SELECT * FROM profiles WHERE role = 'super_admin';

-- Si non, créer un SA
UPDATE profiles
SET role = 'super_admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'votre-email@example.com');
```

---

### **Étape 1.3: Tester la création d'un MC**

```sql
-- Créer une chorale de test si nécessaire
INSERT INTO chorales (nom, description)
VALUES ('Chorale Test', 'Pour tester le système')
RETURNING id;

-- Créer un maître de chœur
SELECT creer_maitre_choeur(
  p_email := 'mc-test@example.com',
  p_full_name := 'Maître Test',
  p_chorale_id := 'uuid-chorale-test',
  p_super_admin_id := (SELECT id FROM profiles WHERE role = 'super_admin' LIMIT 1)
);
```

**Vérifier le résultat:**
```sql
SELECT 
  full_name,
  role,
  est_maitre_choeur,
  affiliation_code,
  lien_affiliation
FROM profiles
WHERE full_name = 'Maître Test';
```

---

### **Étape 1.4: Vérifier les permissions**

```sql
-- Voir les permissions du MC
SELECT get_user_permissions(
  (SELECT id FROM profiles WHERE full_name = 'Maître Test')
);

-- Vérifier une permission spécifique
SELECT has_permission(
  (SELECT id FROM profiles WHERE full_name = 'Maître Test'),
  'validate_members'
);
-- Devrait retourner: true
```

---

## 🎯 PHASE 2: FLUTTER (MOBILE)

### **Étape 2.1: Créer le modèle Permission**

**Fichier:** `lib/models/permission.dart`

```dart
class Permission {
  final String code;
  final String nom;
  final String description;
  final String categorie;
  final String icone;
  final bool actif;
  final String? attribueParNom;
  final DateTime? attribueLe;
  final DateTime? expireLe;

  Permission({
    required this.code,
    required this.nom,
    required this.description,
    required this.categorie,
    required this.icone,
    required this.actif,
    this.attribueParNom,
    this.attribueLe,
    this.expireLe,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      code: json['code'],
      nom: json['nom'],
      description: json['description'],
      categorie: json['categorie'],
      icone: json['icone'],
      actif: json['actif'] ?? true,
      attribueParNom: json['attribue_par'],
      attribueLe: json['attribue_le'] != null 
        ? DateTime.parse(json['attribue_le']) 
        : null,
      expireLe: json['expire_le'] != null 
        ? DateTime.parse(json['expire_le']) 
        : null,
    );
  }
}
```

---

### **Étape 2.2: Créer le provider de permissions**

**Fichier:** `lib/providers/permissions_provider.dart`

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permission.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider pour obtenir toutes les permissions de l'utilisateur
final userPermissionsProvider = FutureProvider<List<Permission>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return [];
  
  try {
    final response = await supabase.rpc('get_user_permissions', 
      params: {'p_user_id': userId}
    );
    
    if (response == null) return [];
    
    final List<dynamic> data = json.decode(response);
    return data.map((p) => Permission.fromJson(p)).toList();
  } catch (e) {
    print('Erreur chargement permissions: $e');
    return [];
  }
});

// Provider pour vérifier une permission spécifique
final hasPermissionProvider = FutureProvider.family<bool, String>((ref, moduleCode) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return false;
  
  try {
    final response = await supabase.rpc('has_permission', params: {
      'p_user_id': userId,
      'p_module_code': moduleCode
    });
    
    return response as bool;
  } catch (e) {
    print('Erreur vérification permission: $e');
    return false;
  }
});

// Provider pour obtenir tous les modules disponibles
final availableModulesProvider = FutureProvider<List<Permission>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  try {
    final response = await supabase
      .from('modules_permissions')
      .select('*')
      .eq('actif', true)
      .order('ordre');
    
    return (response as List)
      .map((m) => Permission.fromJson(m))
      .toList();
  } catch (e) {
    print('Erreur chargement modules: $e');
    return [];
  }
});
```

---

### **Étape 2.3: Créer le widget conditionnel**

**Fichier:** `lib/widgets/permission_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permissions_provider.dart';

class PermissionWidget extends ConsumerWidget {
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    Key? key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermissionAsync = ref.watch(
      hasPermissionProvider(requiredPermission)
    );

    return hasPermissionAsync.when(
      data: (hasPermission) {
        if (hasPermission) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}
```

---

### **Étape 2.4: Adapter le menu HomeScreen**

**Fichier:** `lib/screens/home/home_screen.dart`

```dart
// Ajouter dans le Drawer:

Consumer(
  builder: (context, ref, child) {
    final permissionsAsync = ref.watch(userPermissionsProvider);

    return permissionsAsync.when(
      data: (permissions) {
        return Column(
          children: [
            // Section Administration (si au moins une permission admin)
            if (permissions.any((p) => 
              ['validate_members', 'add_chants', 'assign_permissions']
              .contains(p.code)
            )) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Administration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // Validation des membres
              if (permissions.any((p) => p.code == 'validate_members'))
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Validation des membres'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/members-validation');
                  },
                ),
              
              // Ajouter un chant
              if (permissions.any((p) => p.code == 'add_chants'))
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Ajouter un chant'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/add-chant');
                  },
                ),
              
              // Ajouter chant par pupitre
              if (permissions.any((p) => p.code == 'add_chants_pupitre'))
                ListTile(
                  leading: const Icon(Icons.layers),
                  title: const Text('Ajouter chant par pupitre'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/add-chant-pupitre');
                  },
                ),
              
              // Gestion des permissions
              if (permissions.any((p) => p.code == 'assign_permissions'))
                ListTile(
                  leading: const Icon(Icons.shield),
                  title: const Text('Gestion des permissions'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/manage-permissions');
                  },
                ),
              
              // Mon lien d'affiliation (si maître de chœur)
              if (permissions.any((p) => p.code == 'validate_members'))
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Mon lien d\'affiliation'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/affiliation');
                  },
                ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  },
)
```

---

### **Étape 2.5: Créer l'écran de gestion des permissions**

**Fichier:** `lib/screens/admin/manage_permissions_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/permissions_provider.dart';
import '../../models/permission.dart';

class ManagePermissionsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const ManagePermissionsScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  ConsumerState<ManagePermissionsScreen> createState() => _ManagePermissionsScreenState();
}

class _ManagePermissionsScreenState extends ConsumerState<ManagePermissionsScreen> {
  Set<String> selectedPermissions = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc('get_user_permissions', 
        params: {'p_user_id': widget.userId}
      );
      
      final List<dynamic> data = json.decode(response);
      setState(() {
        selectedPermissions = data.map((p) => p['code'] as String).toSet();
        loading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _savePermissions() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      
      if (currentUserId == null) return;

      // Récupérer toutes les permissions actuelles
      final response = await supabase.rpc('get_user_permissions', 
        params: {'p_user_id': widget.userId}
      );
      final List<dynamic> currentPerms = json.decode(response);
      final currentCodes = currentPerms.map((p) => p['code'] as String).toSet();

      // Permissions à ajouter
      final toAdd = selectedPermissions.difference(currentCodes);
      for (final code in toAdd) {
        await supabase.rpc('attribuer_permission', params: {
          'p_user_id': widget.userId,
          'p_module_code': code,
          'p_attribue_par': currentUserId,
        });
      }

      // Permissions à révoquer
      final toRemove = currentCodes.difference(selectedPermissions);
      for (final code in toRemove) {
        await supabase.rpc('revoquer_permission', params: {
          'p_user_id': widget.userId,
          'p_module_code': code,
          'p_revoque_par': currentUserId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Permissions mises à jour')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(availableModulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions - ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePermissions,
          ),
        ],
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : modulesAsync.when(
            data: (modules) {
              // Grouper par catégorie
              final grouped = <String, List<Permission>>{};
              for (final module in modules) {
                grouped.putIfAbsent(module.categorie, () => []).add(module);
              }

              return ListView(
                children: grouped.entries.map((entry) {
                  return ExpansionTile(
                    title: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: true,
                    children: entry.value.map((module) {
                      return CheckboxListTile(
                        title: Text(module.nom),
                        subtitle: Text(module.description),
                        value: selectedPermissions.contains(module.code),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedPermissions.add(module.code);
                            } else {
                              selectedPermissions.remove(module.code);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
    );
  }
}
```

---

## 🎯 PHASE 3: DASHBOARD WEB

### **Étape 3.1: Créer le hook usePermissions**

**Fichier:** `hooks/usePermissions.ts`

```typescript
import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

interface Permission {
  code: string
  nom: string
  description: string
  categorie: string
  icone: string
  actif: boolean
}

export function usePermissions() {
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchPermissions() {
      try {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const { data, error } = await supabase.rpc('get_user_permissions', {
          p_user_id: user.id
        })

        if (error) throw error

        setPermissions(JSON.parse(data))
      } catch (error) {
        console.error('Erreur permissions:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchPermissions()
  }, [])

  const hasPermission = (code: string): boolean => {
    return permissions.some(p => p.code === code && p.actif)
  }

  return { permissions, hasPermission, loading }
}
```

---

### **Étape 3.2: Créer le composant PermissionGate**

**Fichier:** `components/PermissionGate.tsx`

```typescript
'use client'
import { usePermissions } from '@/hooks/usePermissions'

interface PermissionGateProps {
  permission: string
  children: React.ReactNode
  fallback?: React.ReactNode
}

export function PermissionGate({ 
  permission, 
  children, 
  fallback 
}: PermissionGateProps) {
  const { hasPermission, loading } = usePermissions()

  if (loading) return null

  if (hasPermission(permission)) {
    return <>{children}</>
  }

  return <>{fallback}</>
}
```

---

### **Étape 3.3: Adapter la Sidebar**

**Fichier:** `components/Sidebar.tsx`

```typescript
'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { 
  LayoutDashboard, 
  Music, 
  Users, 
  Building2, 
  BarChart3, 
  FileText,
  LogOut,
  UserCheck,
  Shield,
  Link as LinkIcon
} from 'lucide-react'
import { usePermissions } from '@/hooks/usePermissions'
import { supabase } from '@/lib/supabase'

export default function Sidebar() {
  const pathname = usePathname()
  const { hasPermission, loading } = usePermissions()

  const menuItems = [
    { 
      href: '/dashboard', 
      label: 'Vue d\'ensemble', 
      icon: LayoutDashboard,
      permission: 'view_dashboard'
    },
    { 
      href: '/dashboard/validation', 
      label: 'Validation des membres', 
      icon: UserCheck,
      permission: 'validate_members'
    },
    { 
      href: '/dashboard/affiliation', 
      label: 'Mon lien d\'affiliation', 
      icon: LinkIcon,
      permission: 'validate_members'
    },
    { 
      href: '/dashboard/chorales', 
      label: 'Chorales', 
      icon: Building2,
      permission: 'view_chorales'
    },
    { 
      href: '/dashboard/users', 
      label: 'Utilisateurs', 
      icon: Users,
      permission: 'view_members'
    },
    { 
      href: '/dashboard/permissions', 
      label: 'Gestion des permissions', 
      icon: Shield,
      permission: 'assign_permissions'
    },
    { 
      href: '/dashboard/chants', 
      label: 'Chants', 
      icon: Music,
      permission: 'view_chants'
    },
    { 
      href: '/dashboard/stats', 
      label: 'Statistiques', 
      icon: BarChart3,
      permission: 'view_stats'
    },
    { 
      href: '/dashboard/logs', 
      label: 'Logs', 
      icon: FileText,
      permission: 'view_logs'
    },
  ]

  if (loading) {
    return <div className="w-64 bg-gray-900 text-white min-h-screen p-4">Chargement...</div>
  }

  return (
    <div className="w-64 bg-gray-900 text-white min-h-screen p-4">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">🎵 Admin Dashboard</h1>
        <p className="text-sm text-gray-400">Chorale SaaS</p>
      </div>

      <nav className="space-y-2">
        {menuItems.map((item) => {
          if (!hasPermission(item.permission)) return null

          const Icon = item.icon
          const isActive = pathname === item.href
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                isActive 
                  ? 'bg-blue-600 text-white' 
                  : 'text-gray-300 hover:bg-gray-800'
              }`}
            >
              <Icon size={20} />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      <button
        onClick={async () => {
          await supabase.auth.signOut()
          window.location.href = '/login'
        }}
        className="flex items-center gap-3 px-4 py-3 rounded-lg text-gray-300 hover:bg-gray-800 w-full mt-8"
      >
        <LogOut size={20} />
        <span>Déconnexion</span>
      </button>
    </div>
  )
}
```

---

## ✅ CHECKLIST COMPLÈTE

### **Backend**
- [ ] Migration SQL exécutée
- [ ] Super Admin créé
- [ ] Maître de chœur de test créé
- [ ] Permissions testées

### **Flutter**
- [ ] Modèle Permission créé
- [ ] Provider permissions créé
- [ ] Widget PermissionWidget créé
- [ ] Menu HomeScreen adapté
- [ ] Écran gestion permissions créé
- [ ] Tests effectués

### **Dashboard Web**
- [ ] Hook usePermissions créé
- [ ] Composant PermissionGate créé
- [ ] Sidebar adaptée
- [ ] Page gestion permissions créée
- [ ] Tests effectués

---

## 🎉 RÉSULTAT FINAL

Vous aurez un système où:
- ✅ Le SA crée des MC avec liens d'affiliation
- ✅ Les MC valident leurs membres
- ✅ Les permissions sont modulaires
- ✅ L'interface s'adapte automatiquement
- ✅ Tout est traçable et sécurisé

**C'est exactement ce que vous vouliez ! 🚀**
