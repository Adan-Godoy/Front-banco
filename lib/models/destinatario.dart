// lib/models/destinatario.dart
class Destinatario {
  final String id; // ID del documento Destinatario
  final String alias;
  final String rutDestinatario;
  final String? numeroCuenta;
  final String? cuentaId; // <<< NUEVO CAMPO: ID de la cuenta de destino

  Destinatario({
    required this.id,
    required this.alias,
    required this.rutDestinatario,
    this.numeroCuenta,
    this.cuentaId, // <<< NUEVO CAMPO
  });

  factory Destinatario.fromJson(Map<String, dynamic> json) {
    // El backend envía un objeto populado en 'cuenta_destino_id'
    final cuentaInfo = json['cuenta_destino_id'];
    
    return Destinatario(
      id: json['_id'],
      alias: json['alias'],
      rutDestinatario: json['rut_destinatario'],
      // Leemos los datos desde el objeto anidado si existe
      numeroCuenta: (cuentaInfo is Map) ? cuentaInfo['numero_cuenta'] : null,
      cuentaId: (cuentaInfo is Map) ? cuentaInfo['_id'] : null, // <<< NUEVO CAMPO
    );
  }
}