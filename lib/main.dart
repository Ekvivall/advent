import 'package:advent/ui/home_screen.dart';
import 'package:advent/ui/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final savedId = prefs.getString('calendar_id');
  final savedIsAdmin = prefs.getBool('is_admin') ?? false;
  runApp(MyApp(initialId: savedId, initialIsAdmin: savedIsAdmin));
}

class MyApp extends StatelessWidget {
  final String? initialId;
  final bool initialIsAdmin;

  const MyApp({super.key, this.initialId, required this.initialIsAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advent Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0f3a2e),
      ),
      home: initialId != null
          ? HomeScreen(calendarId: initialId!, isAdmin: initialIsAdmin)
          : const LoginScreen(),
    );
  }
}
