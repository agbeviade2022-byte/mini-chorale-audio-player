# 🔧 GUIDE : Nettoyage des données au logout/login

## 🎯 PROBLÈME RÉSOLU

**Avant :**
```
❌ Utilisateur A se déconnecte
❌ Utilisateur B se connecte
❌ Les données de A restent affichées
❌ Besoin de pull-to-refresh
```

**Après :**
```
✅ Utilisateur A se déconnecte → Données effacées
✅ Utilisateur B se connecte → Nouvelles données chargées
✅ Interface mise à jour automatiquement
✅ Pas besoin de pull-to-refresh
```

---

## 📁 FICHIERS CRÉÉS

1. ✅ **lib/services/app_state_manager.dart** - Service principal
2. ✅ **lib/services/drift_chants_service_extension.dart** - Extension pour nettoyage Drift
3. ✅ **lib/providers/app_state_provider.dart** - Providers Riverpod

---

## 🚀 UTILISATION

### **1. Dans votre écran de login**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final appState = ref.read(appStateManagerProvider);

      // 🔑 LOGIN COMPLET
      // Nettoie les anciennes données + Charge les nouvelles
      final userData = await appState.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // ✅ Succès : Naviguer vers l'accueil
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // ❌ Erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **2. Dans votre écran de profil (logout)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';

class ProfileScreen extends ConsumerWidget {
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final appState = ref.read(appStateManagerProvider);

      // 🚪 LOGOUT COMPLET
      // Efface TOUTES les données
      await appState.logout();

      // ✅ Naviguer vers le login
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de déconnexion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Profil')),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('Non connecté'));
          }

          return Column(
            children: [
              ListTile(
                title: Text(user['profile']['full_name'] ?? 'Sans nom'),
                subtitle: Text(user['profile']['role'] ?? 'Utilisateur'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Déconnexion'),
                onTap: () => _handleLogout(context, ref),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
```

### **3. Dans votre écran d'accueil (vérification)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return isLoggedIn.when(
      data: (loggedIn) {
        if (!loggedIn) {
          // Rediriger vers le login si pas connecté
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Afficher l'accueil
        return Scaffold(
          appBar: AppBar(title: Text('Accueil')),
          body: Center(child: Text('Bienvenue !')),
        );
      },
      loading: () => Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
```

---

## 🔄 FLUX COMPLET

### **LOGOUT**

```
1. Utilisateur clique sur "Déconnexion"
   ↓
2. appState.logout()
   ↓
3. resetAppState()
   ├─ Effacer session Hive
   ├─ Effacer base Drift
   ├─ Effacer tokens sécurisés
   ├─ Effacer toutes les boxes Hive
   └─ Déconnecter Supabase
   ↓
4. Navigation vers /login
   ↓
5. ✅ Écran vide, prêt pour nouvel utilisateur
```

### **LOGIN**

```
1. Utilisateur entre email/password
   ↓
2. appState.login(email, password)
   ↓
3. resetAppState() (nettoyage préventif)
   ↓
4. Connexion Supabase
   ↓
5. loadUserData(userId)
   ├─ Charger profil
   ├─ Synchroniser chants de la chorale
   ├─ Synchroniser favoris
   └─ Synchroniser playlists
   ↓
6. Sauvegarder dans Hive + Drift
   ↓
7. Navigation vers /home
   ↓
8. ✅ Interface affiche les données du nouvel utilisateur
```

---

## 🛡️ CE QUI EST NETTOYÉ

### **Au logout :**

```
✅ Session Hive (token, profil)
✅ Base de données Drift (chants, favoris, playlists, historique)
✅ Tokens sécurisés (SecureStorage)
✅ Toutes les boxes Hive
✅ Session Supabase
```

### **Au login :**

```
✅ Nettoyage préventif (au cas où)
✅ Connexion Supabase
✅ Chargement du profil
✅ Synchronisation des chants de la chorale
✅ Synchronisation des favoris
✅ Synchronisation des playlists
```

---

## 🎯 RÉSULTAT

**Avant :**
```
User A logout → User B login
→ Données de A restent
→ Pull-to-refresh nécessaire
```

**Après :**
```
User A logout → Données effacées
User B login → Nouvelles données chargées
→ Interface mise à jour automatiquement
→ Expérience fluide comme Spotify
```

---

## 🔧 PERSONNALISATION

### **Ajouter d'autres données à nettoyer**

Dans `AppStateManager.resetAppState()` :

```dart
// Ajouter vos propres nettoyages
await _clearCustomCache();
await _clearNotifications();
await _clearDownloads();
```

### **Ajouter d'autres données à charger**

Dans `AppStateManager.loadUserData()` :

```dart
// Ajouter vos propres chargements
await _loadUserSettings(userId);
await _loadUserNotifications(userId);
await _loadUserDownloads(userId);
```

---

## 📊 AVANTAGES

```
✅ Pas de mélange de données entre utilisateurs
✅ Pas besoin de pull-to-refresh
✅ Expérience utilisateur professionnelle
✅ Sécurité renforcée (pas de fuite de données)
✅ Performance optimale (cache propre)
✅ Debugging facilité (état prévisible)
```

---

## 🆘 DÉPANNAGE

### **Les données restent après logout**

**Cause :** Une box Hive ou une table Drift n'est pas nettoyée

**Solution :**
1. Vérifiez `_clearAllHiveBoxes()` - ajoutez vos boxes
2. Vérifiez `clearAllData()` - ajoutez vos tables

### **Les données ne se chargent pas au login**

**Cause :** Erreur dans `loadUserData()`

**Solution :**
1. Vérifiez les logs : `debugPrint` affiche chaque étape
2. Vérifiez les permissions RLS Supabase
3. Vérifiez que la chorale_id existe

### **L'application crash au logout**

**Cause :** Une box Hive n'est pas ouverte

**Solution :**
```dart
if (Hive.isBoxOpen(boxName)) {
  await Hive.box(boxName).clear();
}
```

---

**Date de création :** 2025-11-22  
**Version :** 1.0  
**Auteur :** Cascade AI
