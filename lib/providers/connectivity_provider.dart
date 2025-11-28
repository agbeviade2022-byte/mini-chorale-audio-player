import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/connectivity_service.dart';

// Provider du service de connectivité
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// Provider du stream de connectivité
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectionStream;
});

// Provider pour vérifier la connexion actuelle
final hasConnectionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return await service.hasConnection();
});
