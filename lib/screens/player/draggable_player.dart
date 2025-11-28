import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/widgets/audio_wave.dart';

/// Player draggable qui se transforme du mini au full player
class DraggablePlayer extends ConsumerStatefulWidget {
  const DraggablePlayer({super.key});

  @override
  ConsumerState<DraggablePlayer> createState() => _DraggablePlayerState();
}

class _DraggablePlayerState extends ConsumerState<DraggablePlayer> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  double _currentExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentExtent = _controller.size;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentChant = ref.watch(currentChantProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);
    final shuffleMode = ref.watch(shuffleModeProvider);
    final loopMode = ref.watch(loopModeProvider);
    final playlist = ref.watch(playlistProvider);
    final currentIndex = ref.watch(currentIndexProvider);

    if (currentChant == null) {
      return const SizedBox.shrink();
    }

    // Unwrap AsyncValue
    final position = positionAsync.valueOrNull ?? Duration.zero;
    final duration = durationAsync.valueOrNull ?? Duration.zero;

    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < playlist.length - 1;

    // Calculer l'opacité des éléments du mini player (disparaissent quand on monte)
    final miniPlayerOpacity = (1 - (_currentExtent * 5)).clamp(0.0, 1.0);
    
    // Calculer l'opacité des éléments du full player (apparaissent quand on monte)
    final fullPlayerOpacity = ((_currentExtent - 0.2) * 5).clamp(0.0, 1.0);

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 80 / MediaQuery.of(context).size.height,
      minChildSize: 80 / MediaQuery.of(context).size.height,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: [80 / MediaQuery.of(context).size.height, 1.0],
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            children: [
              // Tête du player (mini player qui se transforme)
              GestureDetector(
                onTap: () {
                  if (_currentExtent < 0.5) {
                    _controller.animateTo(
                      1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Container(
                  height: 80,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Stack(
                    children: [
                      // Mini player (disparaît progressivement)
                      Opacity(
                        opacity: miniPlayerOpacity,
                        child: Row(
                          children: [
                            // Pochette/Icône
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isPlaying
                                  ? const Center(
                                      child: AudioWave(
                                        isPlaying: true,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.music_note,
                                      color: AppTheme.white,
                                      size: 32,
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Infos chant
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentChant.titre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentChant.auteur,
                                    style: TextStyle(
                                      color: AppTheme.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Bouton Play/Pause
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 32,
                                color: AppTheme.white,
                              ),
                              onPressed: () {
                                ref
                                    .read(audioPlayerNotifierProvider.notifier)
                                    .togglePlayPause();
                              },
                            ),
                          ],
                        ),
                      ),

                      // Handle bar (toujours visible)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu du full player (apparaît progressivement)
              Opacity(
                opacity: fullPlayerOpacity,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Grande pochette
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: isPlaying
                            ? const Center(
                                child: AudioWave(
                                  isPlaying: true,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                color: AppTheme.white,
                                size: 120,
                              ),
                      ),

                      const SizedBox(height: 32),

                      // Titre et auteur
                      Text(
                        currentChant.titre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentChant.auteur,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Barre de progression
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: position.inSeconds.toDouble(),
                              max: duration.inSeconds.toDouble().clamp(1, double.infinity),
                              onChanged: (value) {
                                ref
                                    .read(audioPlayerNotifierProvider.notifier)
                                    .seek(Duration(seconds: value.toInt()));
                              },
                              activeColor: AppTheme.gold,
                              inactiveColor: AppTheme.white.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contrôles de lecture
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: shuffleMode
                                  ? AppTheme.gold
                                  : AppTheme.white.withOpacity(0.6),
                            ),
                            iconSize: 28,
                            onPressed: () {
                              ref
                                  .read(audioPlayerNotifierProvider.notifier)
                                  .toggleShuffle();
                            },
                          ),

                          // Précédent
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: AppTheme.white),
                            iconSize: 40,
                            onPressed: hasPrevious
                                ? () {
                                    ref
                                        .read(audioPlayerNotifierProvider.notifier)
                                        .playPrevious();
                                  }
                                : null,
                          ),

                          // Play/Pause
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              onPressed: () {
                                ref
                                    .read(audioPlayerNotifierProvider.notifier)
                                    .togglePlayPause();
                              },
                              color: AppTheme.primaryBlue,
                              iconSize: 32,
                            ),
                          ),

                          // Suivant
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: AppTheme.white),
                            iconSize: 40,
                            onPressed: hasNext
                                ? () {
                                    ref
                                        .read(audioPlayerNotifierProvider.notifier)
                                        .playNext();
                                  }
                                : null,
                          ),

                          // Loop
                          IconButton(
                            icon: Icon(
                              loopMode == LoopMode.off
                                  ? Icons.repeat
                                  : loopMode == LoopMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                              color: loopMode == LoopMode.off
                                  ? AppTheme.white.withOpacity(0.6)
                                  : AppTheme.gold,
                            ),
                            iconSize: 28,
                            onPressed: () {
                              ref
                                  .read(audioPlayerNotifierProvider.notifier)
                                  .toggleLoop();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}
