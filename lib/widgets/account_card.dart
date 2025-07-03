// lib/widgets/account_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cuenta.dart';

class AccountCard extends StatelessWidget {
  final Cuenta cuenta;
  const AccountCard({super.key, required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    String accountTypeName = cuenta.tipo == 'principal' ? 'Cuenta Corriente' : 'Cuenta Ahorro';

    return Container(
      width: MediaQuery.of(context).size.width, // Ocupa el ancho del PageView
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Sección Superior: Nombre y saldo ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountTypeName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N° ${cuenta.numero}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currencyFormatter.format(cuenta.saldo),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          
          const Spacer(), // <--- Esto empuja la parte de abajo al fondo

          // --- Sección Inferior: Último movimiento ---
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Último movimiento',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              if (cuenta.ultimaTransaccion != null)
                Text(
                  currencyFormatter.format(cuenta.ultimaTransaccion!.monto),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                )
              else
                 Text(
                  '-',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
            ],
          )
        ],
      ),
    );
  }
}