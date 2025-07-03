// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'cards/cards_screen.dart';
import 'transfer/transfer_screen.dart';
import '../api/api_service.dart';
import 'auth/login_screen.dart';
import 'notifications/notifications_screen.dart'; // <-- IMPORTAR
import 'package:flutter/foundation.dart'; // <-- IMPORTAR PARA kDebugMode
import 'testing/fraud_test_screen.dart';
import 'package:intl/intl.dart'; 
import 'dart:async'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// <<< CAMBIO: Añadimos WidgetsBindingObserver para detectar cuándo la app vuelve al frente >>>
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  late final List<Widget> _widgetOptions;

  Timer? _utcTimer;
  DateTime _utcTime = DateTime.now().toUtc();
  
  // <<< NUEVO ESTADO PARA LAS NOTIFICACIONES >>>
  int _notificationCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Registrar el observer
    _widgetOptions = <Widget>[
      HomeScreen(key: _homeScreenKey),
      const CardsScreen(),
    ];
    _checkNotifications(); // Cargar al inicio

    _startUtcTimer();
  }

   // <<< NUEVO MÉTODO PARA EL RELOJ >>>
  void _startUtcTimer() {
    // Creamos un timer que se ejecuta cada segundo
    _utcTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) { // Nos aseguramos que el widget todavía exista
        setState(() {
          _utcTime = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Limpiar el observer
     _utcTimer?.cancel();
    super.dispose();
  }

  // Este método se llama cuando el estado del ciclo de vida de la app cambia
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La app volvió a estar en primer plano, recargamos las notificaciones y los datos del home
      _checkNotifications();
      _homeScreenKey.currentState?.reloadData();
    }
  }

  // <<< NUEVO MÉTODO PARA VERIFICAR NOTIFICACIONES >>>
  void _checkNotifications() async {
    final count = await _apiService.getConteoPendientes();
    if (mounted) {
      setState(() {
        _notificationCount = count;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onTransferPressed() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );
    if (result == true) {
      _homeScreenKey.currentState?.reloadData();
    }
  }

  // <<< NUEVO MÉTODO PARA NAVEGAR A NOTIFICACIONES >>>
  void _onNotificationPressed() async {
    // Esperamos un resultado de la pantalla de notificaciones.
    // Podríamos hacer que NotificationsScreen devuelva 'true' si algo cambió.
    // Para ello, tendríamos que modificarla para que haga `Navigator.pop(context, true)`
    // después de una aprobación exitosa.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );

    // <<< LÓGICA SIMPLIFICADA Y ROBUSTA >>>
    // Cuando volvemos de la pantalla de notificaciones, SIEMPRE recargamos todo.
    // Es más simple y seguro que pasar valores de vuelta.
    // El usuario espera que los datos se actualicen después de interactuar con las notificaciones.
    print("Volviendo de Notificaciones. Recargando datos...");
    _checkNotifications();
    _homeScreenKey.currentState?.reloadData();
  }

  void logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Cuentas' : 'Tarjetas'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (kDebugMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'UTC: ${DateFormat('HH:mm:ss').format(_utcTime)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ),
      
          // <<< WIDGET DEL ICONO DE NOTIFICACIÓN >>>
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_notificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _notificationCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _onNotificationPressed,
          ),
           if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              tooltip: 'Laboratorio de Fraude',
              onPressed: () async { // <-- Convertir a async
                // <<< AÑADIR LÓGICA DE RESULTADO >>>
                final result = await Navigator.push<bool>( // <-- Esperar el resultado
                  context,
                  MaterialPageRoute(builder: (context) => const FraudTestScreen()),
                );
                // Si la pantalla de fraude devolvió 'true', recargamos todo
                if (result == true) {
                  print("Simulación generó pendiente. Recargando notificaciones y home.");
                  _checkNotifications();
                  _homeScreenKey.currentState?.reloadData();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.credit_card, color: _selectedIndex == 1 ? Colors.blue : Colors.grey),
              onPressed: () => _onItemTapped(1),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onTransferPressed,
        child: const Icon(Icons.swap_horiz),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}