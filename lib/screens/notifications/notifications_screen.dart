import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaccion.dart';
import '../../api/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  // Usamos una lista directamente en lugar de un Future para tener control total
  List<Transaccion>? _pendientes;
  bool _isLoading = true; // Empezamos en estado de carga
  // Usamos un Set para los IDs que se están procesando individualmente
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPendientes();
  }

  // Carga o recarga la lista de transacciones pendientes
  Future<void> _loadPendientes() async {
    // Si no estamos recargando manualmente, mostramos el indicador de carga principal
    if (_pendientes == null) {
      setState(() => _isLoading = true);
    }
    
    try {
      final data = await _apiService.getTransaccionesPendientes();
      if (mounted) {
        setState(() {
          _pendientes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar las aprobaciones.')),
        );
      }
    }
  }

  // Maneja la acción de aprobar o rechazar una transacción
  void _gestionarTransaccion(String id, String accion) async {
    setState(() {
      _processingIds.add(id); // Añadimos el ID al set para mostrar carga en esa tarjeta
    });

    final success = await _apiService.aprobarRechazarTransaccion(id, accion);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Operación exitosa.' : 'Error en la operación.')),
      );
      if (success) {
        // Si fue exitoso, eliminamos el elemento de la lista localmente para una respuesta visual instantánea
        setState(() {
          _pendientes?.removeWhere((tx) => tx.id == id);
        });
      }
      // Siempre quitamos el ID del set de procesamiento al terminar
      setState(() {
        _processingIds.remove(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprobaciones Pendientes')),
      body: RefreshIndicator(
        onRefresh: _loadPendientes,
        child: _buildBody(),
      ),
    );
  }

  // Método auxiliar para decidir qué mostrar en el cuerpo de la pantalla
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendientes == null) {
      // Esto podría pasar si hay un error de red al inicio
      return const Center(child: Text('No se pudieron cargar los datos. Desliza para reintentar.'));
    }
    if (_pendientes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No tienes transacciones pendientes de aprobación.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _pendientes!.length,
      itemBuilder: (context, index) {
        final tx = _pendientes![index];
        final isCurrentlyProcessing = _processingIds.contains(tx.id);
        return _buildNotificationCard(tx, isCurrentlyProcessing);
      },
    );
  }

  // Widget que construye cada tarjeta de notificación
  Widget _buildNotificationCard(Transaccion tx, bool isProcessing) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Requiere Aprobación',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              tx.detallesFraude?.motivo ?? 'Se requiere tu atención para esta transacción.',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Comercio:', tx.nombreComercio ?? 'Desconocido'),
            _buildDetailRow('Monto:', currencyFormatter.format(tx.monto)),
            _buildDetailRow('Fecha:', DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(tx.fecha)),
            const SizedBox(height: 16),

            // Sección de acciones con la lógica de carga corregida
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: isProcessing
                  ? [ const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)) ] // Muestra el spinner si se está procesando
                  : [ // Muestra los botones si no se está procesando
                      TextButton(
                        onPressed: () => _gestionarTransaccion(tx.id, 'rechazar'),
                        child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _gestionarTransaccion(tx.id, 'aprobar'),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
            )
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las filas de detalle
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}