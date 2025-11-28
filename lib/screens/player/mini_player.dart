import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/screens/player/full_player.dart';
import 'package:mini_chorale_audio_player/main.dart';
import 'package:mini_chorale_audio_player/widgets/marquee_text.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateToZero() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward(from: 0);
  }
  
  @override
  Widget build(BuildContext context) {
    final currentChant = ref.watch(currentChantProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final playlist = ref.watch(playlistProvider);
    final currentIndex = ref.watch(currentIndexProvider);

    if (currentChant == null) {
      return const SizedBox.shrink();
    }
    
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < playlist.length - 1;

    return ValueListenableBuilder<bool>(
      valueListenable: isFullPlayerOpen,
      builder: (context, isFullPlayerModalOpen, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: isBottomSheetOpen,
          builder: (context, isBottomSheetModalOpen, child) {
            // Cacher le mini player quand un modal est ouvert
            if (isFullPlayerModalOpen || isBottomSheetModalOpen) {
              return const SizedBox.shrink();
            }
            
            return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final navContext = navigatorKey.currentContext;
            if (navContext != null) {
              isFullPlayerOpen.value = true;
              showModalBottomSheet(
                context: navContext,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FullPlayerScreen(),
              ).then((_) {
                // Réafficher le mini player quand le modal se ferme
                isFullPlayerOpen.value = false;
              }).catchError((_) {
                // En cas d'erreur, s'assurer de réinitialiser
                isFullPlayerOpen.value = false;
              });
            }
          },
          // Exclure les drags horizontaux pour permettre le swipe
          onHorizontalDragStart: (_) {},
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity( 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress bar
                ref.watch(positionProvider).when(
                  data: (position) {
                    final duration = ref.watch(durationProvider).value;
                    final progress = duration != null && duration.inSeconds > 0
                        ? position.inSeconds / duration.inSeconds
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                      minHeight: 2,
                    );
                  },
                  loading: () => LinearProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                    minHeight: 2,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Player content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        // Row avec album art et titre (derrière)
                        Row(
                          children: [
                            // Album art / icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Song info avec swipe carrousel (clippé)
                            Expanded(
                              child: ClipRect(
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    setState(() {
                                      _dragOffset += details.delta.dx;
                                      // Limiter le drag avec plus de liberté
                                      _dragOffset = _dragOffset.clamp(-300.0, 300.0);
                                    });
                                  },
                                  onHorizontalDragEnd: (details) {
                                    // Détecter la vélocité pour un swipe plus réactif
                                    final velocity = details.primaryVelocity ?? 0;
                                    final shouldSwipe = _dragOffset.abs() > 80 || velocity.abs() > 500;
                                    
                                    if (shouldSwipe && _dragOffset < 0 && hasNext) {
                                      // Swipe gauche (arrière) = suivant
                                      ref.read(audioPlayerNotifierProvider.notifier).playNext();
                                    } else if (shouldSwipe && _dragOffset > 0 && hasPrevious) {
                                      // Swipe droite (avant) = précédent
                                      ref.read(audioPlayerNotifierProvider.notifier).playPrevious();
                                    }
                                    // Animation fluide pour revenir à la position initiale
                                    _animateToZero();
                                  },
                                  child: Stack(
                                    children: [
                                      // Titre précédent (vient de la gauche quand on glisse vers la droite)
                                      if (hasPrevious)
                                        Positioned(
                                          left: -300 + _dragOffset,
                                          right: 300 - _dragOffset,
                                          top: 0,
                                          bottom: 0,
                                          child: Opacity(
                                            opacity: (_dragOffset / 100).clamp(0.0, 1.0),
                                            child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              playlist[currentIndex - 1].titre,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              playlist[currentIndex - 1].auteur,
                                              style: Theme.of(context).textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                          ),
                                        ),
                                      
                                      // Titre suivant (vient de la droite quand on glisse vers la gauche)
                                      if (hasNext)
                                        Positioned(
                                          left: 300 + _dragOffset,
                                          right: -300 - _dragOffset,
                                          top: 0,
                                          bottom: 0,
                                          child: Opacity(
                                            opacity: (-_dragOffset / 100).clamp(0.0, 1.0),
                                            child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              playlist[currentIndex + 1].titre,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              playlist[currentIndex + 1].auteur,
                                              style: Theme.of(context).textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                          ),
                                        ),
                                      
                                      // Titre actuel (au centre)
                                      Positioned(
                                        left: _dragOffset,
                                        right: -_dragOffset,
                                        top: 0,
                                        bottom: 0,
                                        child: Opacity(
                                          opacity: (1 - (_dragOffset.abs() / 100)).clamp(0.0, 1.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                          MarqueeText(
                                            text: currentChant.titre,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            speed: 40.0,
                                            pauseDuration: const Duration(seconds: 2),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currentChant.auteur,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                              ),
                            ),
                            
                            // Espace pour le bouton
                            const SizedBox(width: 48),
                          ],
                        ),
                        
                        // Bouton play au-dessus (devant)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: IconButton(
                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                              onPressed: () {
                                ref
                                    .read(audioPlayerNotifierProvider.notifier)
                                    .togglePlayPause();
                              },
                              color: Theme.of(context).colorScheme.primary,
                              iconSize: 32,
                            ),
                          ),
                        ),
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
      },
    );
  }
}
