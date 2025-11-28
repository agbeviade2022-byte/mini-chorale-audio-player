import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/models/chant.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';

class ChantDetailsScreen extends ConsumerWidget {
  final Chant chant;

  const ChantDetailsScreen({
    super.key,
    required this.chant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChant = ref.watch(currentChantProvider);
    final isPlaying = ref.watch(playingStateProvider).value ?? false;
    final isCurrentChant = currentChant?.id == chant.id;
    final playlist = ref.watch(playlistProvider);
    final allChants = ref.watch(chantsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du chant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Icône
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 120,
                  color: AppTheme.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Titre
            Text(
              chant.titre,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),

            // Auteur
            Text(
              chant.auteur,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.darkGrey.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),

            // Infos
            _buildInfoRow(context, 'Catégorie', chant.categorie),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Durée', chant.dureeFormatee),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Ajouté le',
              '${chant.createdAt.day}/${chant.createdAt.month}/${chant.createdAt.year}',
            ),
            const SizedBox(height: 32),

            // Bouton lecture
            Center(
              child: CustomButton(
                text: isCurrentChant && isPlaying ? 'Pause' : 'Écouter',
                icon: isCurrentChant && isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                onPressed: () async {
                  if (isCurrentChant) {
                    await ref
                        .read(audioPlayerNotifierProvider.notifier)
                        .togglePlayPause();
                  } else {
                    // Utiliser la playlist existante, sinon tous les chants
                    final playlistToUse = playlist.isNotEmpty ? playlist : allChants;
                    await ref
                        .read(audioPlayerNotifierProvider.notifier)
                        .playChant(
                          chant,
                          playlist: playlistToUse.isNotEmpty ? playlistToUse : null,
                        );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
