import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/providers/audio_provider.dart';
import 'package:mini_chorale_audio_player/widgets/audio_wave.dart';
import 'package:mini_chorale_audio_player/screens/player/full_player.dart';
import 'package:mini_chorale_audio_player/main.dart';

/// Player extensible qui s'anime du mini au full player
class ExpandablePlayer extends ConsumerStatefulWidget {
  const ExpandablePlayer({super.key});

  @override
  ConsumerState<ExpandablePlayer> createState() => _ExpandablePlayerState();
}

class _ExpandablePlayerState extends ConsumerState<ExpandablePlayer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animation.addListener(() {
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

  void _expandPlayer() {
    final navContext = navigatorKey.currentContext;
    if (navContext != null) {
      Navigator.of(navContext).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.5),
          pageBuilder: (context, animation, secondaryAnimation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: const FullPlayerScreen(),
            );
          },
        ),
      );
    }
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _expandPlayer,
      onVerticalDragUpdate: (details) {
        // Permettre le drag vers le haut
        if (details.delta.dy < 0) {
          setState(() {
            _dragOffset = (_dragOffset + details.delta.dy / 500).clamp(-1.0, 0.0);
          });
        }
      },
      onVerticalDragEnd: (details) {
        // Si on a drag suffisamment, ouvrir le full player
        if (_dragOffset < -0.3 || details.velocity.pixelsPerSecond.dy < -500) {
          _expandPlayer();
        }
        // Sinon, revenir à la position initiale
        _animationController.reverse();
      },
      onHorizontalDragStart: (_) {},
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Pochette/Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isPlaying
                    ? const Center(
                        child: AudioWave(isPlaying: true, color: Colors.white),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: AppTheme.white,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 12),

              // Infos chant avec swipe
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentChant.auteur,
                      style: TextStyle(
                        color: AppTheme.darkGrey.withOpacity(0.7),
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
                ),
                onPressed: () {
                  ref
                      .read(audioPlayerNotifierProvider.notifier)
                      .togglePlayPause();
                },
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
