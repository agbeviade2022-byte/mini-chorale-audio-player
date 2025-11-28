import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/models/chorale.dart';

class ChoraleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupérer toutes les chorales actives
  Future<List<Chorale>> getAllChorales() async {
    try {
      final response = await _supabase
          .from('chorales')
          .select()
          .eq('statut', 'actif')
          .order('nom', ascending: true);

      return (response as List)
          .map((json) => Chorale.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des chorales: $e');
      rethrow;
    }
  }

  /// Récupérer une chorale par son ID
  Future<Chorale?> getChoraleById(String id) async {
    try {
      final response = await _supabase
          .from('chorales')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Chorale.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération de la chorale: $e');
      return null;
    }
  }

  /// Récupérer une chorale par son slug
  Future<Chorale?> getChoraleBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('chorales')
          .select()
          .eq('slug', slug)
          .maybeSingle();

      if (response == null) return null;
      return Chorale.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération de la chorale: $e');
      return null;
    }
  }

  /// Créer une nouvelle chorale (admin uniquement)
  Future<Chorale> createChorale({
    required String nom,
    required String slug,
    String? description,
    String? logoUrl,
    String? couleurTheme,
    String? emailContact,
    String? telephone,
    String? adresse,
    String? ville,
    String? pays,
    String? siteWeb,
  }) async {
    try {
      final response = await _supabase.from('chorales').insert({
        'nom': nom,
        'slug': slug,
        'description': description,
        'logo_url': logoUrl,
        'couleur_theme': couleurTheme ?? '#6366F1',
        'email_contact': emailContact,
        'telephone': telephone,
        'adresse': adresse,
        'ville': ville,
        'pays': pays ?? 'France',
        'site_web': siteWeb,
        'statut': 'actif',
      }).select().single();

      return Chorale.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la création de la chorale: $e');
      rethrow;
    }
  }

  /// Mettre à jour une chorale (admin uniquement)
  Future<void> updateChorale({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase
          .from('chorales')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la chorale: $e');
      rethrow;
    }
  }

  /// Supprimer une chorale (super admin uniquement)
  Future<void> deleteChorale(String id) async {
    try {
      await _supabase.from('chorales').delete().eq('id', id);
    } catch (e) {
      print('❌ Erreur lors de la suppression de la chorale: $e');
      rethrow;
    }
  }

  /// Récupérer les membres d'une chorale
  Future<int> getMembresCount(String choraleId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('chorale_id', choraleId)
          .count();

      return response.count ?? 0;
    } catch (e) {
      print('❌ Erreur lors du comptage des membres: $e');
      return 0;
    }
  }

  /// Rechercher des chorales par nom
  Future<List<Chorale>> searchChorales(String query) async {
    try {
      final response = await _supabase
          .from('chorales')
          .select()
          .ilike('nom', '%$query%')
          .eq('statut', 'actif')
          .order('nom', ascending: true);

      return (response as List)
          .map((json) => Chorale.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche de chorales: $e');
      return [];
    }
  }
}
