# ✅ Écran de gestion des chorales V2 (natif Flutter)

## 🎯 FONCTIONNALITÉ

Un écran Flutter **natif** pour gérer les chorales directement depuis l'app mobile, avec les **mêmes données que le dashboard web**.

---

## 🔄 DIFFÉRENCE AVEC L'ANCIEN ÉCRAN

### **Ancien écran (v1) :**
```
❌ Utilise des providers et services personnalisés
❌ Peut avoir des données différentes du dashboard
❌ Dépend de choraleServiceProvider
❌ Pas de synchronisation garantie
```

### **Nouveau écran (v2) :**
```
✅ Charge directement depuis Supabase
✅ Mêmes données que le dashboard web
✅ Pas de providers intermédiaires
✅ Synchronisation garantie
✅ Compte les membres en temps réel
```

---

## 📱 FONCTIONNALITÉS

### **1. Liste des chorales**
```
✅ Avatar avec initiale
✅ Nom de la chorale
✅ Description
✅ Nombre de membres (en temps réel)
✅ Ville
✅ Menu d'actions (modifier, supprimer)
```

### **2. Recherche**
```
✅ Recherche par nom
✅ Recherche par ville
✅ Filtrage en temps réel
```

### **3. Statistiques**
```
✅ Total chorales
✅ Total membres (tous les membres de toutes les chorales)
```

### **4. Création de chorale**
```
✅ Nom (obligatoire)
✅ Description
✅ Ville
✅ Pays
✅ Email de contact
✅ Téléphone
✅ Site web
```

### **5. Modification de chorale**
```
✅ Modifier tous les champs
✅ Voir le nombre de membres
```

### **6. Suppression de chorale**
```
✅ Confirmation avant suppression
✅ Avertissement si la chorale a des membres
✅ Les membres deviennent "sans chorale"
```

### **7. Actualisation**
```
✅ Pull-to-refresh
✅ Bouton refresh dans l'AppBar
```

---

## 🎨 APPARENCE

```
┌─────────────────────────────────────┐
│ ← Gestion des chorales      + 🔄  │
├─────────────────────────────────────┤
│ 🔍 Rechercher une chorale...       │
├─────────────────────────────────────┤
│ ┌────────────┐  ┌────────────┐     │
│ │     3      │  │    45      │     │
│ │   Total    │  │   Total    │     │
│ │  chorales  │  │  membres   │     │
│ └────────────┘  └────────────┘     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 🔵 Chorale A                ⋮  │ │
│ │    Chorale de Paris            │ │
│ │    👥 15 membres  📍 Paris     │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🔵 Chorale B                ⋮  │ │
│ │    Chorale de Lyon             │ │
│ │    👥 12 membres  📍 Lyon      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🔵 Chorale C                ⋮  │ │
│ │    Chorale de Marseille        │ │
│ │    👥 18 membres  📍 Marseille │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🔧 DIALOG DE CRÉATION/MODIFICATION

```
┌─────────────────────────────────────┐
│ Créer une chorale                  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐│
│ │ 🎵 Nom de la chorale *          ││
│ │ Chorale A                       ││
│ └─────────────────────────────────┘│
│                                    │
│ ┌─────────────────────────────────┐│
│ │ 📝 Description                  ││
│ │ Une belle chorale...            ││
│ │                                 ││
│ └─────────────────────────────────┘│
│                                    │
│ ┌─────────────────────────────────┐│
│ │ 🏙️ Ville                        ││
│ │ Paris                           ││
│ └─────────────────────────────────┘│
│                                    │
│ ┌─────────────────────────────────┐│
│ │ 🚩 Pays                         ││
│ │ France                          ││
│ └─────────────────────────────────┘│
│                                    │
│ ┌─────────────────────────────────┐│
│ │ 📧 Email de contact             ││
│ │ contact@chorale.fr              ││
│ └─────────────────────────────────┘│
│                                    │
│ ┌─────────────────────────────────┐│
│ │ 📞 Téléphone                    ││
│ │ 01 23 45 67 89                  ││
│ └─────────────────────────────────┘│
│                                    │
│ ┌─────────────────────────────────┐│
│ │ 🌐 Site web                     ││
│ │ https://chorale.fr              ││
│ └─────────────────────────────────┘│
│                                    │
├─────────────────────────────────────┤
│         [Annuler]  [Créer]         │
└─────────────────────────────────────┘
```

---

## 🚀 UTILISATION

### **1. Ouvrir l'écran**

```
Menu (☰) → Administration → Gestion des Chorales
```

### **2. Créer une chorale**

```
1. Cliquez sur + dans l'AppBar
2. Remplissez les champs
3. Cliquez sur "Créer"
4. ✅ Chorale créée
```

### **3. Modifier une chorale**

```
1. Cliquez sur ⋮ à droite de la chorale
2. Cliquez sur "Modifier"
3. Modifiez les champs
4. Cliquez sur "Enregistrer"
5. ✅ Chorale modifiée
```

### **4. Supprimer une chorale**

```
1. Cliquez sur ⋮ à droite de la chorale
2. Cliquez sur "Supprimer"
3. Confirmez
4. ✅ Chorale supprimée
```

### **5. Actualiser la liste**

```
Option 1 : Tirez vers le bas (pull-to-refresh)
Option 2 : Cliquez sur 🔄 dans l'AppBar
```

---

## 📊 AVANTAGES

```
✅ Charge directement depuis Supabase
✅ Mêmes données que le dashboard web
✅ Compte les membres en temps réel
✅ Pas de décalage entre mobile et web
✅ Interface native optimisée
✅ Recherche rapide
✅ Création/modification facile
✅ Avertissement avant suppression
✅ Pull-to-refresh
✅ Gestion d'erreurs
```

---

## 🔍 SÉCURITÉ

### **Visible pour les admins et super admins**

```dart
PermissionGuard(
  permissionCode: 'manage_chorales',
  child: ListTile(
    title: const Text('Gestion des Chorales'),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ChoralesManagementScreenV2(),
        ),
      );
    },
  ),
)
```

**Résultat :**
- ✅ **Super admins** : Peuvent accéder
- ✅ **Admins avec permission** : Peuvent accéder
- ❌ **Membres** : Ne peuvent PAS accéder

---

## 🔧 CODE CRÉÉ

### **Fichiers :**

1. ✅ `lib/screens/admin/chorales_management_screen_v2.dart`
   - Écran complet (600+ lignes)
   - Charge directement depuis Supabase

2. ✅ `lib/screens/home/home_screen.dart` (modifié)
   - Ligne 22 : Import du nouvel écran
   - Ligne 1561 : Utilise ChoralesManagementScreenV2

---

## 📋 FONCTIONS PRINCIPALES

### **_loadChorales()**

```dart
// Charge les chorales depuis Supabase
final choralesData = await _supabase
    .from('chorales')
    .select('*')
    .order('nom');

// Compte les membres pour chaque chorale
final membersCount = await _supabase
    .from('profiles')
    .select('user_id', const FetchOptions(count: CountOption.exact))
    .eq('chorale_id', choraleId);
```

### **_showChoraleDialog()**

```dart
// Affiche le dialog de création/modification
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(chorale == null ? 'Créer' : 'Modifier'),
    content: Column(
      children: [
        TextField(...),  // Nom
        TextField(...),  // Description
        TextField(...),  // Ville
        // etc.
      ],
    ),
  ),
);
```

### **_showDeleteConfirmation()**

```dart
// Affiche la confirmation de suppression
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Supprimer la chorale'),
    content: Text('$membersCount membre(s) seront sans chorale'),
    actions: [
      TextButton(child: Text('Annuler')),
      TextButton(child: Text('Supprimer')),
    ],
  ),
);
```

---

## 🎯 RÉSULTAT

**Maintenant les admins peuvent :**

```
✅ Voir toutes les chorales (mêmes données que le dashboard)
✅ Voir le nombre de membres en temps réel
✅ Créer des chorales
✅ Modifier des chorales
✅ Supprimer des chorales (avec avertissement)
✅ Rechercher rapidement
✅ Actualiser les données
✅ Tout gérer depuis l'app mobile
```

---

## 🆘 DÉPANNAGE

### **Les données sont différentes du dashboard**

**Cause :** Vous utilisez l'ancien écran (v1)

**Solution :**
```dart
// Vérifiez que vous utilisez bien ChoralesManagementScreenV2
import 'package:mini_chorale_audio_player/screens/admin/chorales_management_screen_v2.dart';
```

### **Le nombre de membres est incorrect**

**Cause :** Cache non actualisé

**Solution :**
```
Tirez vers le bas pour actualiser (pull-to-refresh)
```

### **Erreur lors de la création**

**Cause :** Le nom est vide

**Solution :**
```
Le nom de la chorale est obligatoire
```

---

## 📊 COMPARAISON

### **Ancien écran (v1) :**

```
❌ Utilise choraleServiceProvider
❌ Peut avoir des données différentes
❌ Pas de comptage en temps réel
❌ Dépend de providers intermédiaires
```

### **Nouveau écran (v2) :**

```
✅ Charge directement depuis Supabase
✅ Mêmes données que le dashboard
✅ Compte les membres en temps réel
✅ Pas de providers intermédiaires
✅ Synchronisation garantie
```

---

## 🎉 AVANTAGES POUR L'UTILISATEUR

```
✅ Données toujours synchronisées avec le dashboard
✅ Nombre de membres précis
✅ Pas de décalage entre mobile et web
✅ Interface native optimisée
✅ Gestion facile depuis mobile
✅ Avertissement avant suppression
✅ Expérience fluide
```

---

**Date de création :** 2025-11-22  
**Version :** 2.0  
**Auteur :** Cascade AI  
**Fichiers créés :**
- `lib/screens/admin/chorales_management_screen_v2.dart`
- `lib/screens/home/home_screen.dart` (modifié)
