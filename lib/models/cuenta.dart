// lib/models/cuenta.dart
import 'ultima_transaccion.dart';

class Cuenta {
  final String id;
  final String tipo; 
  final double saldo;
  final String numero;
  final UltimaTransaccion? ultimaTransaccion; // <-- CAMBIO CLAVE: puede ser nulo

  Cuenta({
    required this.id,
    required this.tipo,
    required this.saldo,
    required this.numero,
    this.ultimaTransaccion, // <-- CAMBIO CLAVE
  });

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: json['_id'],
      tipo: json['tipo'],
      saldo: (json['saldo'] as num).toDouble(),
      numero: json['numero_cuenta'],
      // <-- CAMBIO CLAVE: Comprobar si existe el dato antes de crearlo
      ultimaTransaccion: json['ultimaTransaccion'] != null
          ? UltimaTransaccion.fromJson(json['ultimaTransaccion'])
          : null,
    );
  }
}