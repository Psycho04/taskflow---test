import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks/auth/login.dart';
import 'package:tasks/auth/register.dart';
import 'package:tasks/pages/home/home.dart';
import 'package:tasks/providers/task_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Management',
        theme: ThemeData(
          primaryColor: const Color(0xFF1A73E8),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        home: const Home(),
        routes: {
          Home.routeName: (context) => const Home(),
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}
