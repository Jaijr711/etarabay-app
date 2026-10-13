import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Shows a beautiful celebration modal when a badge is earned
class BadgeEarnedModal extends StatefulWidget {
  final String title;
  final String emoji;
  final Color color;
  final String description;
  final int starReward;
  final VoidCallback? onContinue;

  const BadgeEarnedModal({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.description,
    this.starReward = 10,
    this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String emoji,
    required Color color,
    required String description,
    int starReward = 10,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BadgeEarnedModal(
        title: title,
        emoji: emoji,
        color: color,
        description: description,
        starReward: starReward,
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<BadgeEarnedModal> createState() => _BadgeEarnedModalState();
}

class _BadgeEarnedModalState extends State<BadgeEarnedModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti behind
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [
                  widget.color,
                  Colors.amber,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                ],
                gravity: 0.2,
                emissionFrequency: 0.06,
                numberOfParticles: 35,
              ),
            ),
          ),

          // Main card
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticOut,
              ).value;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "NEW BADGE" label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'NEW BADGE!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Animated badge circle
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                        border: Border.all(
                          color: Colors.amber,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Star reward
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+${widget.starReward}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onContinue ??
                            () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Awesome!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
