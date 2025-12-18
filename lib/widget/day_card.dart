import 'package:advent/data/advent_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/advent_model.dart';
import '../ui/edit_day_dialog.dart';
import '../ui/gift_dialog.dart';
import '../viewmodels/advent_viewmodel.dart';

class DayCard extends StatelessWidget {
  final int dayNum;
  final AdventDay? data;
  final bool isAdmin;

  const DayCard({
    super.key,
    required this.dayNum,
    this.data,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool isDateReached =
        (now.month == 12 && now.day >= dayNum && now.year == 2025) ||
        (now.year > 2025);
    final hasData = data != null;
    final canOpen = hasData && isDateReached;
    final isFound = data?.isFound ?? false;

    return GestureDetector(
      onTap: () {
        if (isAdmin) {
          if (data != null) {
            final repo = context.read<AdventService>();
            showDialog(
              context: context,
              builder: (_) => Provider.value(
                value: repo,
                child: EditDayDialog(day: data!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Спочатку створи базу кнопкою!")),
            );
          }
        } else {
          if (canOpen) {
            final viewModel = context.read<AdventViewModel>();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: viewModel,
                child: GiftDialog(day: data!),
              ),
            );
          } else {
            String message = 'Ельфи ще пакують цей подарунок! 📦';
            if (hasData && !isDateReached) {
              message = 'Цей день ще не настав! Не підглядай! 🕒';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(milliseconds: 1500),
                backgroundColor: Colors.grey[800],
              ),
            );
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isFound
              ? const LinearGradient(
                  colors: [Color(0xFF1a5f1a), Color(0xFF2d8f2d)],
                )
              : canOpen
              ? const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFDC143C)],
                )
              : LinearGradient(colors: [Colors.grey[700]!, Colors.grey[600]!]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: canOpen
              ? [
                  BoxShadow(
                    color: (isFound ? Colors.green : Colors.red).withAlpha(49),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (isFound && data!.hintImageUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: data!.hintImageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withAlpha(49),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
            if (canOpen)
              Positioned(
                top: 0,
                left: 4,
                child: Text(
                  '❄️',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(149),
                  ),
                ),
              ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isFound)
              const Positioned(
                bottom: 0,
                right: 4,
                child: Icon(Icons.check_circle, size: 18, color: Colors.white),
              ),
            if (!canOpen)
              const Positioned(
                top: 0,
                right: 4,
                child: Icon(Icons.lock, size: 16, color: Colors.white70),
              ),
            if (isAdmin)
              const Positioned(
                top: 2,
                left: 2,
                child: Icon(Icons.edit, size: 16, color: Colors.blue),
              ),
          ],
        ),
      ),
    );
  }
}
