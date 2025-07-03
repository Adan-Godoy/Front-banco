// lib/screens/history/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:intl/intl.dart';
import '../../models/transaccion.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaccion transaccion;

  const TransactionDetailScreen({super.key, required this.transaccion});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final isCompra = transaccion.tipo == 'compra';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Transacción')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID Transacción:', transaccion.id, context),
                const Divider(),
                _buildDetailRow('Tipo:', transaccion.tipo.toUpperCase(), context),
                const Divider(),
                _buildDetailRow('Monto:', currencyFormatter.format(transaccion.monto), context),
                const Divider(),
                _buildDetailRow('Fecha:', DateFormat('dd MMM yyyy, HH:mm').format(transaccion.fecha), context),
                const Divider(),
                if (isCompra && transaccion.nombreComercio != null)
                  _buildDetailRow('Comercio:', transaccion.nombreComercio!, context),
                
                // <<< CAMBIO CLAVE: Mostrar número de cuenta en lugar de ID >>>
                _buildDetailRow(
                  'Cta. Origen:', 
                  transaccion.numeroCuentaOrigen ?? transaccion.cuentaOrigenId, // Muestra el número, o el ID como fallback
                  context
                ),
                
                if (transaccion.cuentaDestinoId != null) ...[
                  const Divider(),
                  _buildDetailRow(
                    'Cta. Destino:', 
                    transaccion.numeroCuentaDestino ?? transaccion.cuentaDestinoId!, // Muestra el número, o el ID como fallback
                    context
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar mejorado con opción de copiar
  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado al portapapeles')),
                );
              },
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}