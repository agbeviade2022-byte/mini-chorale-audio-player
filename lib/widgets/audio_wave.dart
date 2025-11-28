import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mini_chorale_audio_player/config/theme.dart';

class AudioWave extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double height;

  const AudioWave({
    super.key,
    required this.isPlaying,
    this.color = AppTheme.gold,
    this.height = 40,
  });

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(100, widget.height),
          painter: _AudioWavePainter(
            progress: _controller.value,
            color: widget.color,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }
}

class _AudioWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;

  _AudioWavePainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const barCount = 5;
    final barWidth = size.width / (barCount * 2 - 1);

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2;

      final heightMultiplier = isPlaying
          ? (math.sin((progress * 2 * math.pi) + (i * 0.5)) + 1) / 2
          : 0.2;

      final barHeight = size.height * heightMultiplier;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AudioWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
