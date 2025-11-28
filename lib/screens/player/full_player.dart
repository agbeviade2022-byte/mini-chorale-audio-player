import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/widgets/marquee_text.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChant = ref.watch(currentChantProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final shuffleMode = ref.watch(shuffleModeProvider);
    final loopMode = ref.watch(loopModeProvider);

    if (currentChant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lecteur')),
        body: const Center(child: Text('Aucun chant en lecture')),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
              // Handle bar - glissable pour fermer
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Détecter le swipe vers le bas
                  if (details.primaryDelta! > 5) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity( 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    IconButton(
                      icon:
                          const Icon(Icons.expand_more, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    Text(
                      'En lecture',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // TODO: Show options menu
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Album art et Song info avec swipe
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  // Swipe vers la gauche (arrière) = suivant
                  if (details.primaryVelocity! < -500) {
                    ref.read(audioPlayerNotifierProvider.notifier).playNext();
                  }
                  // Swipe vers la droite (avant) = précédent
                  else if (details.primaryVelocity! > 500) {
                    ref.read(audioPlayerNotifierProvider.notifier).playPrevious();
                  }
                },
                child: Column(
                  children: [
                    // Album art
                    Container(
                      width: 280,
                      height: 280,
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 150,
                        color: Colors.white,
                      ),
                    ),

                    // Song info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          MarqueeText(
                            text: currentChant.titre,
                            style:
                                Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                            speed: 50.0,
                            pauseDuration: const Duration(seconds: 3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentChant.auteur,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity( 0.8),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentChant.categorie,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.gold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const SizedBox(height: 32),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    ref.watch(positionProvider).when(
                          data: (position) {
                            final duration = ref.watch(durationProvider).value;
                            return Slider(
                              value: position.inSeconds.toDouble(),
                              max: duration?.inSeconds.toDouble() ?? 0.0,
                              onChanged: (value) {
                                ref
                                    .read(audioPlayerNotifierProvider.notifier)
                                    .seek(Duration(seconds: value.toInt()));
                              },
                              activeColor: AppTheme.gold,
                              inactiveColor: Colors.white.withOpacity( 0.3),
                            );
                          },
                          loading: () => Slider(
                            value: 0,
                            max: 100,
                            onChanged: null,
                            activeColor: AppTheme.gold,
                            inactiveColor: Colors.white.withOpacity( 0.3),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ref.watch(positionProvider).when(
                                data: (position) => Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity( 0.8),
                                  ),
                                ),
                                loading: () => Text(
                                  '0:00',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity( 0.8),
                                  ),
                                ),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                          ref.watch(durationProvider).when(
                                data: (duration) => Text(
                                  _formatDuration(duration ?? Duration.zero),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity( 0.8),
                                  ),
                                ),
                                loading: () => Text(
                                  '0:00',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity( 0.8),
                                  ),
                                ),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: shuffleMode
                            ? AppTheme.gold
                            : Colors.white.withOpacity( 0.6),
                      ),
                      onPressed: () {
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .toggleShuffle();
                      },
                    ),

                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous,
                          color: Colors.white, size: 40),
                      onPressed: () {
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .playPrevious();
                      },
                    ),

                    // Play/Pause
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 48,
                        ),
                        onPressed: () {
                          ref
                              .read(audioPlayerNotifierProvider.notifier)
                              .togglePlayPause();
                        },
                        color: Colors.white,
                      ),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(Icons.skip_next,
                          color: Colors.white, size: 40),
                      onPressed: () {
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .playNext();
                      },
                    ),

                    // Repeat
                    IconButton(
                      icon: Icon(
                        loopMode == LoopMode.off
                            ? Icons.repeat
                            : loopMode == LoopMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                        color: loopMode != LoopMode.off
                            ? AppTheme.gold
                            : Colors.white.withOpacity( 0.6),
                      ),
                      onPressed: () {
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .toggleLoop();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
                ],
              ),
            ),
          ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
