import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/custom_back_button.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MagbasaTulaScreen extends StatefulWidget {
  final int activityIndex;
  final String activityTitle;

  const MagbasaTulaScreen({
    super.key,
    required this.activityIndex,
    required this.activityTitle,
  });

  @override
  State<MagbasaTulaScreen> createState() => _MagbasaTulaScreenState();
}

class _MagbasaTulaScreenState extends State<MagbasaTulaScreen> {
  bool _isCompleted = false;
  bool _isPlaying = false;

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _replayTula() {
    setState(() {
      _isPlaying = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inuulit ang tula...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: AppColors.alphabet,
        elevation: 0,
        title: Text(
          widget.activityTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: CustomBackButton(
          iconColor: Colors.white,
          onPressed: () => Navigator.pop(context, _isCompleted),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Illustration Header
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📖', style: TextStyle(fontSize: 100)),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.activityTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.alphabet.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isPlaying ? '▶️ Nagsasalita ang tula...' : '⏸️ Naka-pause ang tula',
                          style: const TextStyle(
                            color: AppColors.alphabet,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Playback Control Buttons (Play, Pause, Replay)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replay / Repeat Button
                  IconButton(
                    iconSize: 48,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.rotate_ccw, color: Colors.amber, size: 28),
                    ),
                    onPressed: _replayTula,
                    tooltip: 'Ulitin / Replay',
                  ),
                  const SizedBox(width: 24),

                  // Play / Pause Button
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.alphabet,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.alphabet,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? LucideIcons.pause : LucideIcons.play,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Manual Continue Button ("Susunod" / Finish - does not auto jump)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCompleted = true;
                    });
                    // Not dismissible: the delayed callback below pops
                    // exactly two routes, so a child tapping the barrier away
                    // first would otherwise pop this screen AND its parent.
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.circle_check, color: Colors.green, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.poemFinishedGreatJob,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Pop dialog
                      Navigator.of(context).pop(true); // Pop screen
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alphabet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(LucideIcons.circle_check, size: 24),
                  label: const Text(
                    'Susunod (Tapusin ang Aralin)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}