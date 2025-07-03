// lib/models/ultima_transaccion.dart
class UltimaTransaccion {
  final String descripcion;
  final double monto;

  UltimaTransaccion({required this.descripcion, required this.monto});

  factory UltimaTransaccion.fromJson(Map<String, dynamic> json) {
    return UltimaTransaccion(
      descripcion: json['descripcion'] ?? 'Movimiento',
      monto: (json['monto'] as num).toDouble(),
    );
  }
}