// lib/models/transaccion.dart


class DetallesFraude {
  final bool sospechosa;
  final String motivo;

  DetallesFraude({required this.sospechosa, required this.motivo});

  factory DetallesFraude.fromJson(Map<String, dynamic> json) {
    return DetallesFraude(
      sospechosa: json['sospechosa'] ?? false,
      motivo: json['motivo'] ?? 'Sin motivo específico.',
    );
  }
}

class Transaccion {
  final String id;
  final String tipo;
  final double monto;
  final DateTime fecha;
  final String? nombreComercio;


  
  // <<< CAMBIO: Guardaremos el ID y el número de cuenta >>>
  final String cuentaOrigenId;
  final String? numeroCuentaOrigen;
  final String? cuentaDestinoId;
  final String? numeroCuentaDestino;
  final DetallesFraude? detallesFraude;

  Transaccion({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.fecha,
    this.nombreComercio,
    required this.cuentaOrigenId,
    this.numeroCuentaOrigen,
    this.cuentaDestinoId,
    this.numeroCuentaDestino,
    this.detallesFraude,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para extraer datos de los campos populados
    Map<String, String?> _extraerInfoCuenta(dynamic data) {
      if (data == null) return {'id': null, 'numero': null};
      if (data is String) return {'id': data, 'numero': null}; // Caso no populado
      if (data is Map) {
        return {'id': data['_id'], 'numero': data['numero_cuenta']};
      }
      return {'id': null, 'numero': null};
    }

    final infoOrigen = _extraerInfoCuenta(json['cuenta_origen_id']);
    final infoDestino = _extraerInfoCuenta(json['cuenta_destino_id']);

    return Transaccion(
      id: json['_id'],
      tipo: json['tipo'],
      monto: (json['monto'] as num).toDouble(),
      
      // <<< LÓGICA DE FECHA CORREGIDA >>>
      // 1. Intenta parsear 'fecha_transaccion'.
      // 2. Si no existe o es nulo, intenta parsear 'createdAt'.
      // 3. Si ambos fallan, usa la fecha actual como último recurso.
      fecha: DateTime.tryParse(json['fecha_transaccion'] ?? '') ?? 
             DateTime.tryParse(json['createdAt'] ?? '') ?? 
             DateTime.now(),

      nombreComercio: json['nombre_comercio'],
      cuentaOrigenId: infoOrigen['id'] ?? 'N/A',
      numeroCuentaOrigen: infoOrigen['numero'],
      cuentaDestinoId: infoDestino['id'],
      numeroCuentaDestino: infoDestino['numero'],
      detallesFraude: json['detalles_fraude'] != null
          ? DetallesFraude.fromJson(json['detalles_fraude'])
          : null,
    );
  }
}