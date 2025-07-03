// lib/widgets/transaction_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaccion.dart';

class TransactionListItem extends StatelessWidget {
  final Transaccion transaccion;
  final String cuentaPrincipalId;

  const TransactionListItem({
    super.key,
    required this.transaccion,
    required this.cuentaPrincipalId,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar si es un ingreso o egreso para el usuario actual
    // Asumimos que si la cuenta de destino es una de las nuestras, es un ingreso.
    // O si es una compra (siempre es egreso desde la principal).
    // O si es una transferencia enviada (egreso).
    // Esta lógica puede ser más compleja, pero para empezar:
    final bool esIngreso = transaccion.cuentaDestinoId == cuentaPrincipalId && transaccion.tipo == 'transferencia';
    
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final montoFormateado = currencyFormatter.format(transaccion.monto);

    String titulo = 'Operación';
    IconData icono = Icons.swap_horiz;
    Color colorIcono = Colors.grey;

    switch (transaccion.tipo) {
      case 'compra':
        titulo = transaccion.nombreComercio ?? 'Compra';
        icono = Icons.shopping_cart;
        colorIcono = Colors.orange;
        break;
      case 'transferencia':
        titulo = esIngreso ? 'Transferencia Recibida' : 'Transferencia Enviada';
        icono = Icons.swap_horiz;
        colorIcono = esIngreso ? Colors.green : Colors.blue;
        break;
      default:
        titulo = transaccion.tipo.toUpperCase();
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorIcono.withOpacity(0.1),
        child: Icon(icono, color: colorIcono),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        // <<< CAMBIO CLAVE: Usar la propiedad 'fecha' que ya tiene la lógica correcta >>>
        // Y formatearla para que muestre día, mes y año.
        DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(transaccion.fecha),
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Text(
        '${esIngreso ? '+' : '-'}${montoFormateado}',
        style: TextStyle(
          color: esIngreso ? Colors.green : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}