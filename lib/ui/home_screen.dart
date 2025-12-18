import 'package:advent/data/advent_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../viewmodels/advent_viewmodel.dart';
import '../widget/day_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String calendarId;
  final bool isAdmin;

  const HomeScreen({super.key, required this.calendarId, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AdventService(collectionName: calendarId)),
        ChangeNotifierProxyProvider<AdventService, AdventViewModel>(
          create: (context) =>
              AdventViewModel(repository: context.read<AdventService>()),
          update: (context, repo, previous) =>
              previous ?? AdventViewModel(repository: repo),
        ),
      ],
      child: _HomeScreenContent(isAdmin: isAdmin, calendarId: calendarId),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  final bool isAdmin;
  final String calendarId;

  const _HomeScreenContent({required this.isAdmin, required this.calendarId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdventViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Адмін: $calendarId' : '🎄 Адвент 2025 🎄',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('calendar_id');
              await prefs.remove('is_admin');
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f3a2e), Color(0xFF1a5f4a), Color(0xFF0f3a2e)],
          ),
        ),
        child: SafeArea(
          child: viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(context),
                    _buildWeekDays(),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: 31,
                        itemBuilder: (context, index) {
                          final dayNum = index + 1;
                          final data = viewModel.getDayData(dayNum);
                          return DayCard(
                            dayNum: dayNum,
                            data: data,
                            isAdmin: isAdmin,
                          );
                        },
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const Text('🎄', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            'Адвент-календар',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Грудень 2025',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map(
              (d) => SizedBox(
                width: 40,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.grey[600]!, 'Заблоковано'),
          const SizedBox(width: 20),
          _buildLegendItem(const Color(0xFFDC143C), 'Доступно'),
          const SizedBox(width: 20),
          _buildLegendItem(const Color(0xFF2d8f2d), 'Знайдено'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withAlpha(49), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> seedCalendarData(
    BuildContext context, {
    required bool isMomVersion,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final repo = context.read<AdventService>();
    final batch = firestore.batch();

    for (int i = 1; i <= 31; i++) {
      final docRef = firestore
          .collection(repo.collectionName)
          .doc(i.toString());
      batch.set(docRef, {
        'dayNum': i,
        'title': 'День $i',
        'description': isMomVersion ? 'Тут підказка...' : 'Тут побажання...',
        'hintImageUrl': '',
        'hasGift': isMomVersion,
        'isFound': false,
        'audioUrl': '',
      }, SetOptions(merge: true));
    }
    await batch.commit();
    print("Базу створено для: $calendarId");
  }
}
