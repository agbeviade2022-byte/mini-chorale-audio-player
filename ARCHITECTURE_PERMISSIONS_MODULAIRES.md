# 🏗️ ARCHITECTURE: Système de Permissions Modulaires

## 🎯 CONCEPT

Un système **flexible et scalable** où:
- ✅ Le **Super Admin** a tous les accès
- ✅ Le **Maître de Chœur** gère sa chorale avec des permissions personnalisées
- ✅ Les **Membres** peuvent recevoir des permissions spécifiques
- ✅ Les permissions sont des **modules** activables/désactivables
- ✅ L'interface s'adapte **automatiquement** aux permissions

---

## 📊 HIÉRARCHIE

```
┌─────────────────────────────────────────┐
│         SUPER ADMIN (SA)                │
│  - Tous les accès                       │
│  - Crée les maîtres de chœur            │
│  - Attribue n'importe quelle permission │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│      MAÎTRE DE CHŒUR (Admin)            │
│  - Gère sa chorale                      │
│  - Lien d'affiliation unique            │
│  - Valide les membres                   │
│  - Attribue des permissions limitées    │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│           MEMBRES                       │
│  - S'inscrivent via lien d'affiliation  │
│  - Permissions personnalisées           │
│  - Interface adaptée à leurs accès      │
└─────────────────────────────────────────┘
```

---

## 🗄️ STRUCTURE DE LA BASE DE DONNÉES

### **1. Table: `modules_permissions`**

Liste des permissions disponibles (modules).

```sql
CREATE TABLE modules_permissions (
  id UUID PRIMARY KEY,
  code VARCHAR(50) UNIQUE,      -- Ex: 'add_chants'
  nom VARCHAR(100),              -- Ex: 'Ajouter des chants'
  description TEXT,
  categorie VARCHAR(50),         -- 'gestion', 'contenu', 'administration'
  icone VARCHAR(50),             -- Nom de l'icône Lucide
  ordre INTEGER,
  actif BOOLEAN
);
```

**Modules disponibles:**

| Code | Nom | Catégorie |
|------|-----|-----------|
| `view_members` | Voir les membres | gestion |
| `validate_members` | Valider les membres | gestion |
| `edit_members` | Modifier les membres | gestion |
| `delete_members` | Supprimer les membres | gestion |
| `assign_permissions` | Attribuer des permissions | gestion |
| `view_chants` | Voir les chants | contenu |
| `add_chants` | Ajouter des chants | contenu |
| `edit_chants` | Modifier les chants | contenu |
| `delete_chants` | Supprimer des chants | contenu |
| `add_chants_pupitre` | Ajouter chants par pupitre | contenu |
| `view_chorales` | Voir les chorales | administration |
| `manage_chorales` | Gérer les chorales | administration |
| `view_stats` | Voir les statistiques | administration |
| `view_logs` | Voir les logs | administration |
| `manage_system` | Administration système | administration |
| `view_dashboard` | Accès au dashboard | administration |

---

### **2. Table: `user_permissions`**

Permissions attribuées aux utilisateurs.

```sql
CREATE TABLE user_permissions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  module_code VARCHAR(50) REFERENCES modules_permissions(code),
  attribue_par UUID REFERENCES profiles(id),
  attribue_le TIMESTAMP,
  expire_le TIMESTAMP,           -- Optionnel: permission temporaire
  actif BOOLEAN,
  UNIQUE(user_id, module_code)
);
```

---

### **3. Table: `profiles` (modifiée)**

Ajout de champs pour les maîtres de chœur.

```sql
ALTER TABLE profiles ADD COLUMN:
  - est_maitre_choeur BOOLEAN
  - lien_affiliation VARCHAR(100) UNIQUE
  - affiliation_code VARCHAR(20) UNIQUE
  - cree_par UUID (Super Admin qui l'a créé)
  - date_activation TIMESTAMP
```

**Exemple:**
```
Maître de Chœur: Jean Dupont
Chorale: Chorale de Paris
Code: MC-A3F8B2E1
Lien: /register?ref=MC-A3F8B2E1
```

---

### **4. Table: `affiliations`**

Historique des inscriptions via liens d'affiliation.

```sql
CREATE TABLE affiliations (
  id UUID PRIMARY KEY,
  membre_id UUID REFERENCES profiles(id),
  maitre_choeur_id UUID REFERENCES profiles(id),
  code_affiliation VARCHAR(20),
  date_inscription TIMESTAMP,
  statut VARCHAR(20)  -- en_attente, valide, refuse
);
```

---

## 🔧 FONCTIONS SQL

### **1. `creer_maitre_choeur()`**

Crée un maître de chœur avec son lien d'affiliation.

```sql
SELECT creer_maitre_choeur(
  p_email := 'jean@example.com',
  p_full_name := 'Jean Dupont',
  p_chorale_id := 'uuid-chorale',
  p_super_admin_id := 'uuid-sa'
);
```

**Résultat:**
```json
{
  "success": true,
  "profile_id": "uuid-profile",
  "affiliation_code": "MC-A3F8B2E1",
  "lien_affiliation": "/register?ref=MC-A3F8B2E1",
  "email": "jean@example.com"
}
```

**Actions automatiques:**
- ✅ Crée le profil avec `role = 'admin'`
- ✅ Génère un code d'affiliation unique
- ✅ Attribue les permissions de base du maître de chœur
- ✅ Associe à la chorale

---

### **2. `has_permission(user_id, module_code)`**

Vérifie si un utilisateur a une permission.

```sql
SELECT has_permission(
  'uuid-user',
  'add_chants'
);
-- Retourne: true ou false
```

**Logique:**
- Super Admin → Toujours `true`
- Autres → Vérifie dans `user_permissions`

---

### **3. `get_user_permissions(user_id)`**

Retourne toutes les permissions d'un utilisateur.

```sql
SELECT get_user_permissions('uuid-user');
```

**Résultat:**
```json
[
  {
    "code": "add_chants",
    "nom": "Ajouter des chants",
    "description": "...",
    "categorie": "contenu",
    "icone": "Plus",
    "actif": true,
    "attribue_par": "Super Admin",
    "attribue_le": "2025-11-20T10:00:00Z"
  },
  ...
]
```

---

### **4. `attribuer_permission()`**

Attribue une permission à un utilisateur.

```sql
SELECT attribuer_permission(
  p_user_id := 'uuid-membre',
  p_module_code := 'add_chants',
  p_attribue_par := 'uuid-maitre-choeur',
  p_expire_le := NULL  -- Permanent
);
```

**Vérifications:**
- ✅ L'attributeur a la permission `assign_permissions` ou est SA
- ✅ Le module existe
- ✅ Idempotent (peut être appelé plusieurs fois)

---

### **5. `revoquer_permission()`**

Révoque une permission.

```sql
SELECT revoquer_permission(
  p_user_id := 'uuid-membre',
  p_module_code := 'add_chants',
  p_revoque_par := 'uuid-maitre-choeur'
);
```

---

## 🔄 FLUX D'UTILISATION

### **Flux 1: Super Admin crée un Maître de Chœur**

```
1. SA se connecte au dashboard
   ↓
2. VA dans "Gestion des Maîtres de Chœur"
   ↓
3. Clique sur "Créer un Maître de Chœur"
   ↓
4. Remplit le formulaire:
   - Email
   - Nom complet
   - Chorale à assigner
   - Téléphone (optionnel)
   ↓
5. Clique sur "Créer"
   ↓
6. Système:
   - Crée le compte (via Supabase Admin API)
   - Génère le code d'affiliation
   - Attribue les permissions de base
   - Envoie un email avec:
     * Lien de connexion
     * Lien d'affiliation à partager
   ↓
7. SA voit le récapitulatif:
   - Code: MC-A3F8B2E1
   - Lien: /register?ref=MC-A3F8B2E1
   - Permissions attribuées
```

---

### **Flux 2: Maître de Chœur partage son lien**

```
1. MC reçoit son lien d'affiliation
   ↓
2. Partage le lien aux futurs membres:
   - Email
   - WhatsApp
   - SMS
   - Affiche sur un poster
   ↓
3. Membre clique sur le lien
   ↓
4. Arrive sur /register?ref=MC-A3F8B2E1
   ↓
5. Formulaire d'inscription pré-rempli:
   - Code d'affiliation: MC-A3F8B2E1
   - Chorale: Chorale de Paris (automatique)
   ↓
6. Membre remplit:
   - Nom
   - Email
   - Mot de passe
   - Téléphone
   ↓
7. S'inscrit
   ↓
8. Système:
   - Crée le compte
   - Enregistre l'affiliation
   - Statut: en_attente
   - Notifie le MC
```

---

### **Flux 3: Maître de Chœur valide un membre**

```
1. MC se connecte à son dashboard
   ↓
2. Voit une notification: "3 membres en attente"
   ↓
3. VA dans "Validation des membres"
   ↓
4. Voit la liste:
   - Pierre Martin (via MC-A3F8B2E1)
   - Marie Dubois (via MC-A3F8B2E1)
   - Luc Bernard (via MC-A3F8B2E1)
   ↓
5. Clique sur "Valider" pour Pierre
   ↓
6. Modal s'ouvre:
   - Nom: Pierre Martin
   - Email: pierre@example.com
   - Inscrit via: MC-A3F8B2E1
   - Chorale: Chorale de Paris (automatique)
   ↓
7. Clique sur "Valider"
   ↓
8. Système:
   - Statut: valide
   - Pierre peut se connecter
   - Pierre voit les chants de la chorale
```

---

### **Flux 4: Maître de Chœur attribue des permissions**

```
1. MC va dans "Gestion des membres"
   ↓
2. Voit la liste des membres validés
   ↓
3. Clique sur "Permissions" pour Pierre
   ↓
4. Modal s'ouvre avec les modules disponibles:
   ☐ Ajouter des chants
   ☐ Modifier les chants
   ☐ Supprimer les chants
   ☐ Ajouter chants par pupitre
   ☐ Voir les statistiques
   ↓
5. Coche "Ajouter des chants"
   ↓
6. Clique sur "Enregistrer"
   ↓
7. Système:
   - Attribue la permission
   - Pierre voit maintenant "Ajouter un chant" dans son menu
   - Interface de Pierre s'actualise automatiquement
```

---

### **Flux 5: Super Admin attribue n'importe quelle permission**

```
1. SA va dans "Gestion des utilisateurs"
   ↓
2. Cherche un utilisateur (membre ou MC)
   ↓
3. Clique sur "Permissions"
   ↓
4. Voit TOUS les modules disponibles:
   ☐ Voir les membres
   ☐ Valider les membres
   ☐ Modifier les membres
   ☐ Supprimer les membres
   ☐ Attribuer des permissions
   ☐ Ajouter des chants
   ☐ Modifier les chants
   ☐ Supprimer les chants
   ☐ Gérer les chorales
   ☐ Voir les statistiques
   ☐ Voir les logs
   ☐ Administration système
   ↓
5. Coche les modules souhaités
   ↓
6. Clique sur "Enregistrer"
   ↓
7. Système actualise l'interface de l'utilisateur
```

---

## 💻 IMPLÉMENTATION FLUTTER

### **1. Provider des permissions**

```dart
// lib/providers/permissions_provider.dart

final userPermissionsProvider = FutureProvider<List<Permission>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return [];
  
  final response = await supabase.rpc('get_user_permissions', 
    params: {'p_user_id': userId}
  );
  
  final List<dynamic> data = json.decode(response);
  return data.map((p) => Permission.fromJson(p)).toList();
});

final hasPermissionProvider = FutureProvider.family<bool, String>((ref, moduleCode) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return false;
  
  final response = await supabase.rpc('has_permission', params: {
    'p_user_id': userId,
    'p_module_code': moduleCode
  });
  
  return response as bool;
});
```

---

### **2. Widget conditionnel**

```dart
// lib/widgets/permission_widget.dart

class PermissionWidget extends ConsumerWidget {
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

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
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}
```

**Utilisation:**
```dart
PermissionWidget(
  requiredPermission: 'add_chants',
  child: ListTile(
    leading: Icon(Icons.add),
    title: Text('Ajouter un chant'),
    onTap: () => Navigator.push(...),
  ),
)
```

---

### **3. Menu dynamique**

```dart
// lib/screens/home/home_screen.dart

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(userPermissionsProvider);

    return permissionsAsync.when(
      data: (permissions) {
        return Drawer(
          child: ListView(
            children: [
              // Toujours visible
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Accueil'),
                onTap: () => Navigator.pop(context),
              ),
              
              // Conditionnel: Ajouter un chant
              if (permissions.any((p) => p.code == 'add_chants'))
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Ajouter un chant'),
                  onTap: () => Navigator.push(...),
                ),
              
              // Conditionnel: Validation des membres
              if (permissions.any((p) => p.code == 'validate_members'))
                ListTile(
                  leading: Icon(Icons.check),
                  title: Text('Validation des membres'),
                  onTap: () => Navigator.push(...),
                ),
              
              // Conditionnel: Gestion des permissions
              if (permissions.any((p) => p.code == 'assign_permissions'))
                ListTile(
                  leading: Icon(Icons.shield),
                  title: Text('Gestion des permissions'),
                  onTap: () => Navigator.push(...),
                ),
            ],
          ),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (_, __) => Text('Erreur'),
    );
  }
}
```

---

## 🌐 IMPLÉMENTATION DASHBOARD WEB

### **1. Hook des permissions**

```tsx
// hooks/usePermissions.ts

export function usePermissions() {
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchPermissions() {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      const { data } = await supabase.rpc('get_user_permissions', {
        p_user_id: user.id
      })

      setPermissions(JSON.parse(data))
      setLoading(false)
    }

    fetchPermissions()
  }, [])

  const hasPermission = (code: string) => {
    return permissions.some(p => p.code === code && p.actif)
  }

  return { permissions, hasPermission, loading }
}
```

---

### **2. Composant conditionnel**

```tsx
// components/PermissionGate.tsx

export function PermissionGate({ 
  permission, 
  children, 
  fallback 
}: {
  permission: string
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  const { hasPermission, loading } = usePermissions()

  if (loading) return <div>Chargement...</div>

  if (hasPermission(permission)) {
    return <>{children}</>
  }

  return <>{fallback}</>
}
```

**Utilisation:**
```tsx
<PermissionGate permission="add_chants">
  <Link href="/dashboard/chants/add">
    <Plus size={20} />
    Ajouter un chant
  </Link>
</PermissionGate>
```

---

### **3. Sidebar dynamique**

```tsx
// components/Sidebar.tsx

export default function Sidebar() {
  const { hasPermission } = usePermissions()

  const menuItems = [
    { 
      href: '/dashboard', 
      label: 'Vue d\'ensemble', 
      icon: LayoutDashboard,
      permission: 'view_dashboard'
    },
    { 
      href: '/dashboard/validation', 
      label: 'Validation', 
      icon: UserCheck,
      permission: 'validate_members'
    },
    { 
      href: '/dashboard/chants', 
      label: 'Chants', 
      icon: Music,
      permission: 'view_chants'
    },
    { 
      href: '/dashboard/permissions', 
      label: 'Permissions', 
      icon: Shield,
      permission: 'assign_permissions'
    },
  ]

  return (
    <nav>
      {menuItems.map((item) => {
        if (!hasPermission(item.permission)) return null

        return (
          <Link key={item.href} href={item.href}>
            <item.icon size={20} />
            {item.label}
          </Link>
        )
      })}
    </nav>
  )
}
```

---

## 📋 PAGES À CRÉER

### **1. Page: Créer un Maître de Chœur (SA uniquement)**

**Fichier:** `app/dashboard/maitres-choeur/create/page.tsx`

**Fonctionnalités:**
- Formulaire de création
- Sélection de la chorale
- Génération automatique du code d'affiliation
- Affichage du lien à partager
- Envoi d'email automatique

---

### **2. Page: Gestion des Permissions**

**Fichier:** `app/dashboard/permissions/page.tsx`

**Fonctionnalités:**
- Liste des utilisateurs
- Modal pour attribuer/révoquer des permissions
- Affichage des permissions actuelles
- Historique des attributions

---

### **3. Page: Mon Lien d'Affiliation (MC)**

**Fichier:** `app/dashboard/affiliation/page.tsx`

**Fonctionnalités:**
- Affichage du code et du lien
- QR Code pour partage facile
- Statistiques: nombre d'inscriptions via le lien
- Liste des membres affiliés

---

### **4. Page: Inscription avec Affiliation**

**Fichier:** `app/register/page.tsx`

**Fonctionnalités:**
- Détection du paramètre `?ref=MC-XXX`
- Pré-remplissage de la chorale
- Affichage du nom du maître de chœur
- Message: "Vous rejoignez la Chorale de Paris"

---

## 🧪 EXEMPLES D'UTILISATION

### **Exemple 1: Super Admin crée un MC**

```sql
-- 1. Super Admin crée un maître de chœur
SELECT creer_maitre_choeur(
  p_email := 'jean.dupont@example.com',
  p_full_name := 'Jean Dupont',
  p_chorale_id := (SELECT id FROM chorales WHERE nom = 'Chorale de Paris'),
  p_super_admin_id := (SELECT id FROM profiles WHERE role = 'super_admin' LIMIT 1)
);

-- Résultat:
-- {
--   "success": true,
--   "affiliation_code": "MC-A3F8B2E1",
--   "lien_affiliation": "/register?ref=MC-A3F8B2E1"
-- }
```

---

### **Exemple 2: MC attribue une permission**

```sql
-- Jean Dupont (MC) donne la permission d'ajouter des chants à Pierre
SELECT attribuer_permission(
  p_user_id := (SELECT id FROM profiles WHERE full_name = 'Pierre Martin'),
  p_module_code := 'add_chants',
  p_attribue_par := (SELECT id FROM profiles WHERE full_name = 'Jean Dupont')
);
```

---

### **Exemple 3: Vérifier les permissions de Pierre**

```sql
-- Voir toutes les permissions de Pierre
SELECT get_user_permissions(
  (SELECT id FROM profiles WHERE full_name = 'Pierre Martin')
);

-- Vérifier une permission spécifique
SELECT has_permission(
  (SELECT id FROM profiles WHERE full_name = 'Pierre Martin'),
  'add_chants'
);
-- Retourne: true
```

---

### **Exemple 4: SA attribue une permission système**

```sql
-- Super Admin donne la permission de gérer les chorales à Jean
SELECT attribuer_permission(
  p_user_id := (SELECT id FROM profiles WHERE full_name = 'Jean Dupont'),
  p_module_code := 'manage_chorales',
  p_attribue_par := (SELECT id FROM profiles WHERE role = 'super_admin' LIMIT 1)
);
```

---

## ✅ AVANTAGES DU SYSTÈME

### **1. Flexibilité**
- ✅ Permissions granulaires
- ✅ Attribution/révocation en temps réel
- ✅ Permissions temporaires possibles

### **2. Scalabilité**
- ✅ Ajout facile de nouveaux modules
- ✅ Pas de modification de code pour ajouter une permission
- ✅ Gestion centralisée

### **3. Sécurité**
- ✅ RLS policies sur toutes les tables
- ✅ Vérification à chaque action
- ✅ Historique des attributions

### **4. UX**
- ✅ Interface s'adapte automatiquement
- ✅ Pas de boutons inutiles
- ✅ Expérience personnalisée

### **5. Traçabilité**
- ✅ Qui a donné quelle permission
- ✅ Quand
- ✅ À qui

---

## 🚀 DÉPLOIEMENT

### **Étape 1: Exécuter la migration**

```sql
-- Sur Supabase SQL Editor:
-- migration_systeme_permissions_modulaires.sql
```

### **Étape 2: Créer les pages Flutter**

```bash
# Créer les fichiers:
lib/providers/permissions_provider.dart
lib/widgets/permission_widget.dart
lib/screens/admin/manage_permissions_screen.dart
lib/screens/admin/create_maitre_choeur_screen.dart
lib/screens/admin/affiliation_screen.dart
```

### **Étape 3: Créer les pages Web**

```bash
# Créer les fichiers:
app/dashboard/maitres-choeur/create/page.tsx
app/dashboard/permissions/page.tsx
app/dashboard/affiliation/page.tsx
hooks/usePermissions.ts
components/PermissionGate.tsx
```

### **Étape 4: Tester**

```
1. Créer un MC via SA
2. MC partage son lien
3. Membre s'inscrit via le lien
4. MC valide le membre
5. MC attribue des permissions
6. Vérifier que l'interface s'adapte
```

---

## 🎉 CONCLUSION

Ce système offre:
- ✅ **Hiérarchie claire**: SA → MC → Membres
- ✅ **Permissions modulaires**: Activables/désactivables
- ✅ **Liens d'affiliation**: Inscription facilitée
- ✅ **Interface dynamique**: S'adapte aux permissions
- ✅ **Scalable**: Facile d'ajouter des modules
- ✅ **Sécurisé**: RLS + Vérifications SQL
- ✅ **Traçable**: Historique complet

**C'est exactement ce que vous vouliez ! 🚀**

---

**Date:** 20 novembre 2025
**Statut:** ✅ Architecture complète
**Prêt à implémenter:** Oui
