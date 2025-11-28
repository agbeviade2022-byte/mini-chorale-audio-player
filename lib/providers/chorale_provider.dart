import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/models/chorale.dart';
import 'package:mini_chorale_audio_player/services/chorale_service.dart';

// Provider du service
final choraleServiceProvider = Provider<ChoraleService>((ref) {
  return ChoraleService();
});

// Provider pour récupérer toutes les chorales
final choralesListProvider = FutureProvider<List<Chorale>>((ref) async {
  final service = ref.watch(choraleServiceProvider);
  return await service.getAllChorales();
});

// Provider pour récupérer une chorale par ID
final choraleByIdProvider = FutureProvider.family<Chorale?, String>((ref, id) async {
  final service = ref.watch(choraleServiceProvider);
  return await service.getChoraleById(id);
});

// Provider pour rechercher des chorales
final choraleSearchProvider = FutureProvider.family<List<Chorale>, String>((ref, query) async {
  final service = ref.watch(choraleServiceProvider);
  if (query.isEmpty) {
    return await service.getAllChorales();
  }
  return await service.searchChorales(query);
});

// State notifier pour gérer l'état de la chorale sélectionnée
class SelectedChoraleNotifier extends StateNotifier<Chorale?> {
  SelectedChoraleNotifier() : super(null);

  void selectChorale(Chorale chorale) {
    state = chorale;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedChoraleProvider = StateNotifierProvider<SelectedChoraleNotifier, Chorale?>((ref) {
  return SelectedChoraleNotifier();
});
