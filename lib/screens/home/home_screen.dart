// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../api/api_service.dart';
import '../../models/cuenta.dart';
import '../../models/transaccion.dart'; // <-- IMPORTAR
import '../../widgets/account_card.dart';
import '../../widgets/transaction_list_item.dart'; // <-- IMPORTAR
import '../history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // <<< CAMBIO 1: Usamos un solo Future para cargar todo a la vez >>>
  late Future<Map<String, dynamic>> _dataFuture;
  final ApiService _apiService = ApiService();
  final _pageController = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // <<< CAMBIO 2: Nuevo método para cargar cuentas y transacciones juntas >>>
  void _loadAllData() {
    _dataFuture = _fetchData();
  }
  
  Future<Map<String, dynamic>> _fetchData() async {
    // Usamos Future.wait para ejecutar ambas llamadas a la API en paralelo
    final results = await Future.wait([
      _apiService.getCuentas(),
      _apiService.getHistorial(),
    ]);
    return {
      'cuentas': results[0] as List<Cuenta>,
      'transacciones': results[1] as List<Transaccion>,
    };
  }

  void reloadData() {
    if (!mounted) return;
    setState(() {
      _loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // <<< CAMBIO 3: El FutureBuilder ahora espera un Map >>>
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!['cuentas'].isEmpty) {
          return const Center(child: Text('No se encontraron datos.'));
        }

        final List<Cuenta> cuentas = snapshot.data!['cuentas'];
        final List<Transaccion> transacciones = snapshot.data!['transacciones'];
        cuentas.sort((a, b) => a.tipo == 'principal' ? -1 : 1);
        
        // Obtenemos el ID de la cuenta principal para pasarlo al list item
        final cuentaPrincipalId = cuentas.firstWhere((c) => c.tipo == 'principal').id;

        // <<< CAMBIO 4: La UI ahora usa una ListView para poder hacer scroll >>>
        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Text('Tus Cuentas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
            ),
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: cuentas.length,
                itemBuilder: (context, index) {
                  return AccountCard(cuenta: cuentas[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: cuentas.length,
                onDotClicked: (index) => _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                effect: WormEffect(dotHeight: 8, dotWidth: 8, activeDotColor: Colors.blue.shade300, dotColor: Colors.grey.shade300),
              ),
            ),
             const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              // <<< CAMBIO: Convertir en una Fila con un botón >>>
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Actividad Reciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                    },
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // <<< CAMBIO 5: Construimos la lista de transacciones >>>
            if (transacciones.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No hay movimientos recientes.')))
            else
              ListView.builder(
                // Esto es crucial para que una ListView dentro de otra ListView funcione
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transacciones.length,
                itemBuilder: (context, index) {
                  return TransactionListItem(
                    transaccion: transacciones[index],
                    cuentaPrincipalId: cuentaPrincipalId,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}