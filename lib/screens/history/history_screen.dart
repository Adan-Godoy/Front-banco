import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../models/transaccion.dart';
import '../../widgets/transaction_list_item.dart';
import 'transaction_detail_screen.dart';
import '../../models/cuenta.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();

  // La variable del Future ahora puede ser nula para evitar el error de inicialización
  Future<List<Transaccion>>? _historialFuture;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _cuentaPrincipalId;

  @override
  void initState() {
    super.initState();
    // Llamamos a la función que carga todos los datos necesarios al inicio
    _fetchInitialDataAndHistorial();
  }

  // Unificamos la lógica de carga para asegurar el orden correcto
  void _fetchInitialDataAndHistorial() async {
    // Primero, obtenemos el ID de la cuenta principal, es un paso rápido y necesario
    if (_cuentaPrincipalId == null) {
      try {
        final cuentas = await _apiService.getCuentas();
        if (mounted && cuentas.isNotEmpty) {
          // Usamos setState para que la UI sepa que este valor ha cambiado, aunque no lo vea directamente
          setState(() {
            _cuentaPrincipalId = cuentas.firstWhere((c) => c.tipo == 'principal', orElse: () => cuentas.first).id;
          });
        }
      } catch (e) {
        // Manejar error si no se pueden obtener las cuentas
        print("Error obteniendo ID de cuenta principal: $e");
      }
    }
    
    // Ahora que podríamos tener el ID, procedemos a cargar el historial.
    // Asignamos el Future dentro de setState para que el FutureBuilder reaccione.
    setState(() {
      _historialFuture = _apiService.getHistorial(fechaInicio: _fechaInicio, fechaFin: _fechaFin);
    });
  }

  // El método de filtrado simplemente actualiza las fechas y vuelve a llamar a la carga
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _fechaInicio ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _fechaFin ?? DateTime.now(),
    );

    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)).toUtc(),
      lastDate: DateTime.now().toUtc(),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _fechaInicio = newDateRange.start;
        _fechaFin = newDateRange.end;
      });
      // Volvemos a llamar a la función de carga principal
      _fetchInitialDataAndHistorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Transacciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filtrar por fecha',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSummary(),
          Expanded(
            // Manejamos el caso en que el Future aún no ha sido asignado
            child: _historialFuture == null
                ? const Center(child: CircularProgressIndicator()) // Estado de carga inicial
                : FutureBuilder<List<Transaccion>>(
                    future: _historialFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final transacciones = snapshot.data ?? [];
                      if (transacciones.isEmpty) {
                        return const Center(child: Text('No se encontraron transacciones en este rango.'));
                      }
                      return ListView.builder(
                        itemCount: transacciones.length,
                        itemBuilder: (context, index) {
                          final transaccion = transacciones[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionDetailScreen(transaccion: transaccion),
                                ),
                              );
                            },
                            child: TransactionListItem(
                              transaccion: transaccion,
                              // Aseguramos que no sea nulo, aunque en un flujo normal siempre tendrá valor
                              cuentaPrincipalId: _cuentaPrincipalId ?? '', 
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    if (_fechaInicio == null && _fechaFin == null) {
      return const SizedBox.shrink();
    }
    final format = DateFormat('dd MMM yyyy', 'es_ES');
    String text = 'Desde: ${format.format(_fechaInicio!)} - Hasta: ${format.format(_fechaFin!)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Text(text, textAlign: TextAlign.center)),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _fechaInicio = null;
                _fechaFin = null;
              });
              _fetchInitialDataAndHistorial();
            },
          )
        ],
      ),
    );
  }
}