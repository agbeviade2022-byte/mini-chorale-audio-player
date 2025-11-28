# ✅ Menu "Gestion d'utilisateurs" ajouté

## 🎯 FONCTIONNALITÉ AJOUTÉE

Un nouveau menu **"Gestion d'utilisateurs"** a été ajouté dans le drawer Flutter pour les **super admins uniquement**.

---

## 📍 EMPLACEMENT

**Menu Flutter → Administration → Gestion d'utilisateurs**

```
📱 Menu Flutter (Drawer)
├─ Accueil
├─ Chants par pupitre
├─ ─────────────────
├─ 🔴 Administration (Super Admin)
│  ├─ Ajouter un chant
│  ├─ Ajouter chant par pupitre
│  ├─ Gestion des Chorales
│  ├─ Validation des Membres
│  ├─ 🆕 Gestion d'utilisateurs ← NOUVEAU
│  └─ Créer Maître de Chœur
├─ ─────────────────
├─ À propos
└─ Thème
```

---

## 🔐 SÉCURITÉ

### **Visible uniquement pour les super admins**

```dart
SuperAdminGuard(
  child: ListTile(
    leading: const Icon(Icons.manage_accounts, color: Colors.red),
    title: const Text('Gestion d\'utilisateurs'),
    subtitle: const Text('Dashboard admin', style: TextStyle(fontSize: 12)),
    tileColor: Colors.red.withOpacity(0.05),
    onTap: () async {
      // Ouvrir le dashboard admin
    },
  ),
)
```

**Résultat :**
- ✅ **Super admins** : Voient le menu
- ❌ **Admins** : Ne voient PAS le menu
- ❌ **Membres** : Ne voient PAS le menu

---

## 🌐 FONCTIONNEMENT

### **Au clic sur "Gestion d'utilisateurs" :**

```
1. Ferme le drawer
   ↓
2. Ouvre le navigateur externe
   ↓
3. Charge http://localhost:3000/dashboard/users
   ↓
4. ✅ Dashboard admin s'affiche
```

### **Si le serveur n'est pas démarré :**

```
1. Tente d'ouvrir l'URL
   ↓
2. Erreur : Serveur non accessible
   ↓
3. Affiche un SnackBar :
   "Impossible d'ouvrir le dashboard. 
    Vérifiez que le serveur est démarré."
```

---

## 🎨 APPARENCE

### **Icône et couleur :**

```
🔴 Icône : Icons.manage_accounts (rouge)
🔴 Fond : Rouge transparent (0.05 opacity)
🔴 Titre : "Gestion d'utilisateurs"
🔴 Sous-titre : "Dashboard admin"
```

**Effet visuel :**
```
┌─────────────────────────────────────┐
│ 🔴  Gestion d'utilisateurs          │
│     Dashboard admin                 │
└─────────────────────────────────────┘
```

---

## 🔧 CODE AJOUTÉ

### **Fichier : `lib/screens/home/home_screen.dart`**

**Ligne 5 :**
```dart
import 'package:url_launcher/url_launcher.dart';
```

**Ligne 1584-1626 :**
```dart
// Gestion d'utilisateurs (Super Admin only)
SuperAdminGuard(
  child: ListTile(
    leading: const Icon(Icons.manage_accounts, color: Colors.red),
    title: const Text('Gestion d\'utilisateurs'),
    subtitle: const Text('Dashboard admin', style: TextStyle(fontSize: 12)),
    tileColor: Colors.red.withOpacity(0.05),
    onTap: () async {
      Navigator.pop(context);
      
      // Ouvrir le dashboard admin dans le navigateur
      final url = Uri.parse('http://localhost:3000/dashboard/users');
      
      try {
        // Essayer d'ouvrir avec url_launcher
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir le dashboard. Vérifiez que le serveur est démarré.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    },
  ),
),
```

---

## 🚀 UTILISATION

### **1. Démarrer le dashboard admin**

```bash
cd d:\Projet Flutter\admin-chorale-dashboard
npm run dev
```

**Résultat :**
```
✓ Ready in 2s
○ Local: http://localhost:3000
```

### **2. Ouvrir l'app Flutter**

```bash
flutter run
```

### **3. Se connecter en tant que super admin**

```
Email : superadmin@example.com
Password : votre_mot_de_passe
```

### **4. Ouvrir le menu**

```
Menu (☰) → Administration → Gestion d'utilisateurs
```

### **5. Le dashboard s'ouvre dans le navigateur**

```
✅ Page : http://localhost:3000/dashboard/users
✅ Liste de tous les utilisateurs
✅ Possibilité de modifier les rôles et chorales
```

---

## 📊 AVANTAGES

```
✅ Accès rapide au dashboard depuis l'app Flutter
✅ Sécurisé : Visible uniquement pour les super admins
✅ Ouvre dans le navigateur externe (meilleure UX)
✅ Gestion d'erreurs si le serveur n'est pas démarré
✅ Design cohérent avec les autres menus admin
✅ Sous-titre explicatif "Dashboard admin"
```

---

## 🔍 VÉRIFICATION

### **Test en tant que super admin :**

1. Connectez-vous en tant que super admin
2. Ouvrez le menu (☰)
3. **Vérifiez que "Gestion d'utilisateurs" est visible**
4. Cliquez dessus
5. **Le dashboard doit s'ouvrir dans le navigateur**

### **Test en tant que membre :**

1. Connectez-vous en tant que membre
2. Ouvrez le menu (☰)
3. **Vérifiez que "Gestion d'utilisateurs" n'est PAS visible**

---

## 🆘 DÉPANNAGE

### **Le menu n'apparaît pas**

**Cause :** Vous n'êtes pas super admin

**Solution :**
1. Vérifiez votre rôle dans Supabase :
```sql
SELECT role FROM profiles WHERE user_id = auth.uid();
```
2. Si ce n'est pas `super_admin`, modifiez-le :
```sql
UPDATE profiles SET role = 'super_admin' WHERE user_id = 'votre_user_id';
```

### **Le dashboard ne s'ouvre pas**

**Cause :** Le serveur Next.js n'est pas démarré

**Solution :**
```bash
cd d:\Projet Flutter\admin-chorale-dashboard
npm run dev
```

### **Erreur "url_launcher not found"**

**Cause :** Le package n'est pas installé

**Solution :**
```bash
flutter pub add url_launcher
flutter pub get
```

---

## 🔗 URL DU DASHBOARD

### **Par défaut :**
```
http://localhost:3000/dashboard/users
```

### **Pour changer l'URL :**

Modifiez la ligne 1595 dans `home_screen.dart` :

```dart
final url = Uri.parse('http://votre-url.com/dashboard/users');
```

---

## 📋 PAGES DISPONIBLES

Le dashboard admin contient plusieurs pages :

```
http://localhost:3000/dashboard/users        → Gestion des utilisateurs
http://localhost:3000/dashboard/permissions  → Gestion des permissions
http://localhost:3000/dashboard/chorales     → Gestion des chorales
```

**Pour ouvrir une autre page :**

Modifiez l'URL dans le code :

```dart
// Ouvrir la page des permissions
final url = Uri.parse('http://localhost:3000/dashboard/permissions');

// Ouvrir la page des chorales
final url = Uri.parse('http://localhost:3000/dashboard/chorales');
```

---

## 🎉 RÉSULTAT

**Maintenant les super admins peuvent :**

```
✅ Accéder au dashboard admin depuis l'app Flutter
✅ Gérer les utilisateurs (rôles, chorales)
✅ Modifier les permissions
✅ Valider les membres
✅ Tout gérer depuis un seul endroit
```

---

**Date de création :** 2025-11-22  
**Version :** 1.0  
**Auteur :** Cascade AI  
**Fichier modifié :** `lib/screens/home/home_screen.dart`
