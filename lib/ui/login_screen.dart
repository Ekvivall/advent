import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _processLogin() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      bool isAdmin = false;
      String calendarId = input;

      if (input.startsWith("admin:")) {
        isAdmin = true;
        calendarId = input.replaceAll("admin:", "");
      }

      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection(calendarId);

      final snapshot = await collectionRef.limit(1).get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          await _showCreationDialog(calendarId, isAdmin);
        }
      } else {
        await _saveAndNavigate(calendarId, isAdmin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Помилка: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreationDialog(String calendarId, bool isAdmin) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("🎄 Новий календар!"),
        content: Text(
          "Календаря з кодом '$calendarId' ще не існує.\nДавайте створимо його!",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _createDatabase(
                calendarId,
                isMomVersion: false,
              );
              await _saveAndNavigate(calendarId, isAdmin);
            },
            child: const Text("Тільки листівки)"),
          ),

          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _createDatabase(calendarId, isMomVersion: true);
              await _saveAndNavigate(calendarId, isAdmin);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "З подарунками",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDatabase(
    String newCalendarId, {
    required bool isMomVersion,
  }) async {
    setState(() => _isLoading = true);

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      final sourceCollection = firestore.collection('calendar');
      final sourceSnapshot = await sourceCollection.get();

      if (sourceSnapshot.docs.isEmpty) {
        print("⚠️ Шаблон 'calendar' порожній! Створюю пусті дні.");
        for (int i = 1; i <= 31; i++) {
          final docRef = firestore.collection(newCalendarId).doc(i.toString());
          batch.set(docRef, {
            'dayNum': i,
            'title': 'День $i',
            'description': 'Вітання...',
            'hintImageUrl': '',
            'hasGift': isMomVersion,
            'isFound': false,
            'audioUrl': '',
          });
        }
      } else {
        print("📋 Копіюю дані з шаблону...");

        for (var doc in sourceSnapshot.docs) {
          final data = doc.data();
          final docId = doc.id;

          final destRef = firestore.collection(newCalendarId).doc(docId);

          batch.set(destRef, {
            'dayNum': data['dayNum'] ?? int.tryParse(docId) ?? 0,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'hintImageUrl': data['hintImageUrl'] ?? '',
            'audioUrl': data['audioUrl'] ?? '',

            'hasGift': isMomVersion,
            'isFound': false,
          });
        }
      }
      final registryRef = firestore.collection('metadata').doc('registry');
      batch.set(registryRef, {
        'calendars': FieldValue.arrayUnion([newCalendarId]),
      }, SetOptions(merge: true));

      await batch.commit();
      print("✅ Створено базу для: $newCalendarId (на основі шаблону)");
    } catch (e) {
      print("Помилка створення: $e");
    }
  }

  Future<void> _saveAndNavigate(String calendarId, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_id', calendarId);

    if (isAdmin) {
      await prefs.setBool('is_admin', true);
    } else {
      await prefs.remove('is_admin');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(calendarId: calendarId, isAdmin: isAdmin),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🎅", style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 10),
                  const Text(
                    "Advent Calendar",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _controller,
                    onSubmitted: (_) => _isLoading ? null : _processLogin(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Введіть код',
                      hintText: 'напр. mom або admin:mom',
                      prefixIcon: const Icon(Icons.vpn_key),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "УВІЙТИ",
                              style: TextStyle(
                                color: Colors.white,
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
      ),
    );
  }
}
