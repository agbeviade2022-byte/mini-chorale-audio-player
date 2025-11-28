import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';

class SupabaseChantsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer tous les chants
  Future<List<Chant>> getAllChants() async {
    try {
      final response = await _supabase
          .from('chants')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((chant) => Chant.fromMap(chant)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les chants par catégorie
  Future<List<Chant>> getChantsByCategory(String categorie) async {
    try {
      final response = await _supabase
          .from('chants')
          .select()
          .eq('categorie', categorie)
          .eq('type', 'normal')
          .order('created_at', ascending: false);

      return (response as List).map((chant) => Chant.fromMap(chant)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Rechercher des chants
  Future<List<Chant>> searchChants(String query) async {
    try {
      final response = await _supabase
          .from('chants')
          .select()
          .eq('type', 'normal')
          .or('titre.ilike.%$query%,auteur.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((chant) => Chant.fromMap(chant)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un chant par ID
  Future<Chant?> getChantById(String id) async {
    try {
      final response =
          await _supabase.from('chants').select().eq('id', id).single();

      return Chant.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Ajouter un chant
  Future<Chant> addChant({
    required String titre,
    required String categorie,
    required String auteur,
    required String urlAudio,
    required int duree,
    String type = 'normal',
  }) async {
    try {
      final response = await _supabase
          .from('chants')
          .insert({
            'titre': titre,
            'categorie': categorie,
            'auteur': auteur,
            'url_audio': urlAudio,
            'duree': duree,
            'type': type,
          })
          .select()
          .single();

      return Chant.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour un chant
  Future<Chant> updateChant({
    required String id,
    String? titre,
    String? categorie,
    String? auteur,
    String? urlAudio,
    int? duree,
    String? lyrics,
    String? partitionUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (titre != null) updates['titre'] = titre;
      if (categorie != null) updates['categorie'] = categorie;
      if (auteur != null) updates['auteur'] = auteur;
      if (urlAudio != null) updates['url_audio'] = urlAudio;
      if (duree != null) updates['duree'] = duree;
      if (lyrics != null) updates['lyrics'] = lyrics;
      if (partitionUrl != null) updates['partition_url'] = partitionUrl;

      final response = await _supabase
          .from('chants')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Chant.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un chant
  Future<void> deleteChant(String id) async {
    try {
      await _supabase.from('chants').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer toutes les catégories uniques
  Future<List<String>> getAllCategories() async {
    try {
      final response = await _supabase
          .from('chants')
          .select('categorie')
          .eq('type', 'normal')
          .order('categorie');

      final categories = (response as List)
          .map((item) => item['categorie'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      rethrow;
    }
  }

  // Stream des chants (temps réel)
  Stream<List<Chant>> getChantsStream() {
    return _supabase
        .from('chants')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((chant) => Chant.fromMap(chant)).toList());
  }

  // Récupérer les chants par type
  Future<List<Chant>> getChantsByType(String type) async {
    try {
      final response = await _supabase
          .from('chants')
          .select()
          .eq('type', type)
          .order('created_at', ascending: false);

      return (response as List).map((chant) => Chant.fromMap(chant)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les chants par pupitre
  Future<List<Chant>> getChantsByPupitre(String pupitre) async {
    try {
      final response = await _supabase
          .from('chants')
          .select()
          .eq('type', 'pupitre')
          .eq('categorie', pupitre)
          .order('created_at', ascending: false);

      return (response as List).map((chant) => Chant.fromMap(chant)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
