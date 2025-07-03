// lib/models/tarjeta.dart
import 'package:intl/intl.dart';

class Tarjeta {
  final String id;
  final String usuarioId;
  final String cuentaId;
  final String numero;
  final String cvv;
  final String fechaVencimiento; // La convertiremos a formato "MM/yy"
  final String estado;
  final double limiteDiario;
  final double limiteSinAprobacion;
  // NOTA: El nombre del titular no viene en el schema de Tarjeta.
  // Para mostrarlo, el backend tendría que "popular" los datos del usuario.
  // Por ahora, lo dejaremos fuera para evitar errores.

  Tarjeta({
    required this.id,
    required this.usuarioId,
    required this.cuentaId,
    required this.numero,
    required this.cvv,
    required this.fechaVencimiento,
    required this.estado,
    required this.limiteDiario,
    required this.limiteSinAprobacion,
  });

  factory Tarjeta.fromJson(Map<String, dynamic> json) {
    // El backend envía una fecha completa (ISO String), la formateamos a MM/yy
    String formattedDate = "N/A";
    if (json['fecha_vencimiento'] != null) {
      final date = DateTime.parse(json['fecha_vencimiento']);
      formattedDate = DateFormat('MM/yy').format(date);
    }
    final limites = json['limites'] as Map<String, dynamic>? ?? {};

    return Tarjeta(
      id: json['_id'],
      usuarioId: json['usuario_id'],
      cuentaId: json['cuenta_id'],
      numero: json['numero'],
      cvv: json['cvv'],
      fechaVencimiento: formattedDate,
      estado: json['estado'],
      limiteDiario: (limites['monto_diario'] as num? ?? 200000).toDouble(),
      limiteSinAprobacion: (limites['compras_sin_aprobacion'] as num? ?? 5000).toDouble(),
    );
  }
}