import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

import '../data/advent_model.dart';
import '../viewmodels/advent_viewmodel.dart';

class GiftDialog extends StatefulWidget {
  final AdventDay day;
  final File? previewImage;
  final bool isPreview;

  const GiftDialog({
    super.key,
    required this.day,
    this.previewImage,
    this.isPreview = false,
  });

  @override
  State<GiftDialog> createState() => _GiftDialogState();
}

class _GiftDialogState extends State<GiftDialog> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late bool _showTreat;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    _showTreat = widget.isPreview ? false : widget.day.isFound;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      value: _showTreat ? 1.0 : 0.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _playMusic();
  }

  Future<void> _playMusic() async {
    if (widget.day.audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setVolume(0.5);
        await _audioPlayer.play(UrlSource(widget.day.audioUrl));
      } catch (e) {
        debugPrint("Audio error: $e");
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onActionPressed() {
    if (!widget.isPreview) {
      context.read<AdventViewModel>().markAsFound(widget.day.id);
    }

    setState(() {
      _showTreat = true;
    });

    _confettiController.play();
    _scaleController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasGift = widget.day.hasGift;

    Widget imageWidget;
    if (widget.previewImage != null) {
      imageWidget = Image.file(
        widget.previewImage!,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.day.hintImageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.day.hintImageUrl,
        placeholder: (c, u) => Container(
          height: 280,
          color: Colors.white10,
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        errorWidget: (c, u, e) => Container(
          height: 280,
          color: Colors.white10,
          child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
        ),
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        height: 280,
        color: Colors.white10,
        child: const Center(child: Icon(Icons.star, size: 60, color: Colors.white54)),
      );
    }

    String titleText = _showTreat
        ? (hasGift ? "Ура! Знайдено! 🎉" : "Чудово! 🥰")
        : widget.day.title;

    String descriptionText = widget.day.description;

    String? statusText;
    if (_showTreat) {
      statusText = hasGift ? "Смачного! ❤️" : "Ти молодець! ❤️";
    }

    String buttonText = hasGift ? "🎁 Подарунок знайдено!" : "Прочитано / Виконано";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _showTreat
                    ? [const Color(0xFF1a5f1a), const Color(0xFF2d8f2d)] // Зелений
                    : [const Color(0xFF8B0000), const Color(0xFFDC143C)], // Червоний
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(49), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  ScaleTransition(
                    scale: _showTreat ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageWidget,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          descriptionText,
                          style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.4),
                          textAlign: TextAlign.center,
                        ),

                        if (statusText != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            statusText,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_showTreat)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFA500).withAlpha(149), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onActionPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text("Закрити", style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          Positioned(
            top: -50,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.03,
              numberOfParticles: 25,
              maxBlastForce: 25,
              minBlastForce: 12,
              gravity: 0.3,
            ),
          ),

          Positioned(
            top: -12,
            right: -12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8B0000)),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}