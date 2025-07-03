// lib/main.dart
import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart'; // <-- Cambiado
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  // Necesario para el formateo de fechas y monedas en español
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLoginStatus() async {
    final token = await ApiService().getToken();
    return token != null;
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Bancario',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8), // Un fondo gris claro
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const MainScreen(); // <-- Si está logueado, va a MainScreen
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}