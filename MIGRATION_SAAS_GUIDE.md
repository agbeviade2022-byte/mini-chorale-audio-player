# 🚀 Guide de Migration SaaS Multi-Tenant

## 📋 Vue d'Ensemble

Ce guide détaille la transformation de **Mini Chorale Audio Player** d'une application simple vers une **plateforme SaaS B2B** où chaque chorale dispose de son espace privé avec abonnement.

---

## ✅ Ce Qui Est Déjà Fait

### 1. **Script SQL de Migration** ✅
- Fichier : `migration_saas_multi_tenant.sql`
- Contenu :
  - ✅ Tables : `chorales`, `membres`, `invitations`, `abonnements`, `ecoutes`
  - ✅ Modification de la table `chants` (ajout `chorale_id`)
  - ✅ Row Level Security (RLS) complet
  - ✅ Triggers et fonctions automatiques
  - ✅ Vues de statistiques

### 2. **Modèles Dart** ✅
- ✅ `lib/models/chorale.dart` - Modèle Chorale
- ✅ `lib/models/membre.dart` - Modèle Membre
- ✅ `lib/models/invitation.dart` - Modèle Invitation
- ⏳ `lib/models/chant.dart` - À adapter (ajouter `choraleId`)

---

## 🔄 Étapes de Migration

### **Phase 1 : Base de Données** (1-2 jours)

#### 1.1 Exécuter le Script SQL
```bash
# Dans Supabase SQL Editor
1. Ouvrir migration_saas_multi_tenant.sql
2. Copier tout le contenu
3. Exécuter dans Supabase
4. Vérifier les logs de succès
```

#### 1.2 Migrer les Données Existantes
```sql
-- Créer une chorale par défaut pour les données existantes
INSERT INTO chorales (
    nom,
    slug,
    email_contact,
    admin_user_id,
    abonnement_actif,
    plan,
    date_debut_abonnement,
    date_fin_abonnement
) VALUES (
    'Chorale St Camille',
    'chorale-st-camille',
    'admin@chorale-st-camille.com',
    (SELECT id FROM auth.users WHERE email = 'votre-email-admin@example.com'),
    true,
    'pro',
    NOW(),
    NOW() + INTERVAL '1 year'
) RETURNING id;

-- Associer tous les chants existants à cette chorale
UPDATE chants 
SET chorale_id = 'ID_DE_LA_CHORALE_CREEE'
WHERE chorale_id IS NULL;

-- Créer des membres pour tous les utilisateurs existants
INSERT INTO membres (
    chorale_id,
    user_id,
    nom_complet,
    email,
    role,
    statut,
    date_acceptation
)
SELECT 
    'ID_DE_LA_CHORALE_CREEE',
    p.user_id,
    p.full_name,
    au.email,
    CASE WHEN p.role = 'admin' THEN 'chef' ELSE 'choriste' END,
    'actif',
    NOW()
FROM profiles p
JOIN auth.users au ON au.id = p.user_id;
```

---

### **Phase 2 : Adapter le Modèle Chant** (30 min)

#### 2.1 Modifier `lib/models/chant.dart`
```dart
class Chant {
  // ... champs existants ...
  
  // NOUVEAUX CHAMPS
  final String? choraleId;        // ✨ NOUVEAU
  final String? uploadedBy;       // ✨ NOUVEAU (ID du membre)
  final double? tailleMb;         // ✨ NOUVEAU
  final String visibilite;        // ✨ NOUVEAU ('tous' ou 'pupitre_specifique')
  final String? pupitreCible;     // ✨ NOUVEAU
  final int nombreEcoutes;        // ✨ NOUVEAU
  final DateTime? derniereEcoute; // ✨ NOUVEAU

  Chant({
    // ... paramètres existants ...
    this.choraleId,
    this.uploadedBy,
    this.tailleMb,
    this.visibilite = 'tous',
    this.pupitreCible,
    this.nombreEcoutes = 0,
    this.derniereEcoute,
  });

  // Adapter fromMap et toMap
  factory Chant.fromMap(Map<String, dynamic> map) {
    return Chant(
      // ... champs existants ...
      choraleId: map['chorale_id'] as String?,
      uploadedBy: map['uploaded_by'] as String?,
      tailleMb: (map['taille_mb'] as num?)?.toDouble(),
      visibilite: map['visibilite'] as String? ?? 'tous',
      pupitreCible: map['pupitre_cible'] as String?,
      nombreEcoutes: map['nombre_ecoutes'] as int? ?? 0,
      derniereEcoute: map['derniere_ecoute'] != null
          ? DateTime.parse(map['derniere_ecoute'] as String)
          : null,
    );
  }
}
```

---

### **Phase 3 : Services Supabase** (2-3 jours)

#### 3.1 Créer `lib/services/chorale_service.dart`
```dart
class ChoraleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Créer une chorale
  Future<Chorale> createChorale({
    required String nom,
    required String slug,
    required String emailContact,
    String plan = 'trial',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    final response = await _supabase.from('chorales').insert({
      'nom': nom,
      'slug': slug,
      'email_contact': emailContact,
      'admin_user_id': userId,
      'plan': plan,
      'abonnement_actif': true,
      'date_debut_abonnement': DateTime.now().toIso8601String(),
      'date_fin_abonnement': DateTime.now()
          .add(Duration(days: plan == 'trial' ? 7 : 30))
          .toIso8601String(),
    }).select().single();

    return Chorale.fromMap(response);
  }

  // Récupérer les chorales de l'utilisateur
  Future<List<Chorale>> getMesChorales() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('chorales')
        .select()
        .eq('admin_user_id', userId);

    return (response as List).map((e) => Chorale.fromMap(e)).toList();
  }

  // Récupérer une chorale par ID
  Future<Chorale?> getChorale(String choraleId) async {
    final response = await _supabase
        .from('chorales')
        .select()
        .eq('id', choraleId)
        .maybeSingle();

    return response != null ? Chorale.fromMap(response) : null;
  }

  // Mettre à jour une chorale
  Future<void> updateChorale(String choraleId, Map<String, dynamic> data) async {
    await _supabase.from('chorales').update(data).eq('id', choraleId);
  }
}
```

#### 3.2 Créer `lib/services/membre_service.dart`
```dart
class MembreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer les membres d'une chorale
  Future<List<Membre>> getMembres(String choraleId) async {
    final response = await _supabase
        .from('membres')
        .select()
        .eq('chorale_id', choraleId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Membre.fromMap(e)).toList();
  }

  // Récupérer le membre actuel dans une chorale
  Future<Membre?> getMonMembre(String choraleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('membres')
        .select()
        .eq('chorale_id', choraleId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null ? Membre.fromMap(response) : null;
  }

  // Inviter un membre
  Future<Invitation> inviterMembre({
    required String choraleId,
    required String email,
    String role = 'choriste',
    String? pupitre,
    String? message,
  }) async {
    final response = await _supabase.from('invitations').insert({
      'chorale_id': choraleId,
      'email': email,
      'role': role,
      if (pupitre != null) 'pupitre': pupitre,
      if (message != null) 'message': message,
    }).select().single();

    return Invitation.fromMap(response);
  }

  // Accepter une invitation
  Future<Membre> accepterInvitation(String token) async {
    // 1. Récupérer l'invitation
    final invitResponse = await _supabase
        .from('invitations')
        .select()
        .eq('token', token)
        .single();

    final invitation = Invitation.fromMap(invitResponse);

    if (!invitation.estValide) {
      throw Exception('Invitation expirée ou invalide');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    // 2. Créer le membre
    final membreResponse = await _supabase.from('membres').insert({
      'chorale_id': invitation.choraleId,
      'user_id': userId,
      'nom_complet': invitation.nomComplet ?? 'Nouveau membre',
      'email': invitation.email,
      'role': invitation.role,
      if (invitation.pupitre != null) 'pupitre': invitation.pupitre,
      'statut': 'actif',
      'date_acceptation': DateTime.now().toIso8601String(),
    }).select().single();

    // 3. Marquer l'invitation comme acceptée
    await _supabase.from('invitations').update({
      'statut': 'accepte',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', invitation.id);

    return Membre.fromMap(membreResponse);
  }
}
```

---

### **Phase 4 : Providers Riverpod** (1 jour)

#### 4.1 Créer `lib/providers/chorale_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/chorale_service.dart';
import 'package:mini_chorale_audio_player/models/chorale.dart';

// Service provider
final choraleServiceProvider = Provider<ChoraleService>((ref) {
  return ChoraleService();
});

// Provider des chorales de l'utilisateur
final mesChoralesProvider = FutureProvider<List<Chorale>>((ref) async {
  final service = ref.watch(choraleServiceProvider);
  return await service.getMesChorales();
});

// Provider de la chorale active
final choraleActiveProvider = StateProvider<Chorale?>((ref) => null);

// Provider d'une chorale spécifique
final choraleProvider = FutureProvider.family<Chorale?, String>((ref, choraleId) async {
  final service = ref.watch(choraleServiceProvider);
  return await service.getChorale(choraleId);
});
```

#### 4.2 Créer `lib/providers/membre_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/membre_service.dart';
import 'package:mini_chorale_audio_player/models/membre.dart';

// Service provider
final membreServiceProvider = Provider<MembreService>((ref) {
  return MembreService();
});

// Provider des membres d'une chorale
final membresProvider = FutureProvider.family<List<Membre>, String>((ref, choraleId) async {
  final service = ref.watch(membreServiceProvider);
  return await service.getMembres(choraleId);
});

// Provider du membre actuel
final monMembreProvider = FutureProvider.family<Membre?, String>((ref, choraleId) async {
  final service = ref.watch(membreServiceProvider);
  return await service.getMonMembre(choraleId);
});
```

---

### **Phase 5 : Écrans UI** (3-4 jours)

#### 5.1 Écran de Sélection/Création de Chorale
```dart
// lib/screens/chorale/chorale_selection_screen.dart
class ChoraleSelectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choralesAsync = ref.watch(mesChoralesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mes Chorales')),
      body: choralesAsync.when(
        data: (chorales) {
          if (chorales.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            itemCount: chorales.length,
            itemBuilder: (context, index) {
              final chorale = chorales[index];
              return _buildChoraleCard(context, ref, chorale);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChoraleDialog(context),
        icon: Icon(Icons.add),
        label: Text('Créer une chorale'),
      ),
    );
  }
}
```

#### 5.2 Dashboard Chef de Chorale
```dart
// lib/screens/chorale/dashboard_chef_screen.dart
class DashboardChefScreen extends ConsumerWidget {
  final String choraleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choraleAsync = ref.watch(choraleProvider(choraleId));
    final membresAsync = ref.watch(membresProvider(choraleId));

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: choraleAsync.when(
        data: (chorale) {
          if (chorale == null) return Center(child: Text('Chorale non trouvée'));
          
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildStatsCards(chorale),
                _buildMembresSection(membresAsync),
                _buildChantsSection(chorale),
                _buildAbonnementSection(chorale),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
```

---

## 📊 Tableau de Bord des Tâches

| Phase | Tâche | Durée | Statut |
|-------|-------|-------|--------|
| **1** | Exécuter script SQL | 30 min | ⏳ À faire |
| **1** | Migrer données existantes | 1h | ⏳ À faire |
| **2** | Adapter modèle Chant | 30 min | ⏳ À faire |
| **3** | Créer ChoraleService | 4h | ⏳ À faire |
| **3** | Créer MembreService | 4h | ⏳ À faire |
| **3** | Créer InvitationService | 2h | ⏳ À faire |
| **4** | Créer providers | 4h | ⏳ À faire |
| **5** | Écran sélection chorale | 4h | ⏳ À faire |
| **5** | Dashboard chef | 8h | ⏳ À faire |
| **5** | Gestion membres | 6h | ⏳ À faire |
| **5** | Système d'invitation | 4h | ⏳ À faire |
| **6** | Intégration Stripe | 8h | ⏳ À faire |
| **6** | Intégration CinetPay | 6h | ⏳ À faire |
| **7** | Tests complets | 8h | ⏳ À faire |

**Total estimé : ~60 heures (1.5-2 semaines)**

---

## 🎯 Prochaines Étapes Immédiates

1. **Exécuter le script SQL dans Supabase** ✅
2. **Migrer les données existantes** ✅
3. **Adapter le modèle Chant** ✅
4. **Créer les services** ⏳
5. **Créer les providers** ⏳
6. **Créer les écrans UI** ⏳

---

## 💡 Conseils

- **Testez chaque phase** avant de passer à la suivante
- **Gardez une copie de backup** de la DB avant migration
- **Utilisez un environnement de dev** séparé
- **Documentez les changements** au fur et à mesure

---

## 📞 Support

Pour toute question sur la migration, référez-vous à ce guide ou consultez la documentation Supabase.

**Bonne migration ! 🚀**
