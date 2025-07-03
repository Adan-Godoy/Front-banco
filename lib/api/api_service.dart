// lib/api/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cuenta.dart';
import '../models/tarjeta.dart';
import '../models/destinatario.dart';
import '../models/transaccion.dart';

class ApiService {
  late Dio _dio;
  final String _baseUrl = 'http://localhost:3000';

  ApiService() {
    _dio = Dio(BaseOptions(baseUrl: _baseUrl));

    // Interceptor para añadir el token a todas las peticiones protegidas
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Podrías manejar errores globales aquí, como un 401 (token expirado)
        print('Error en petición a la API: ${e.response?.statusCode} - ${e.response?.data}');
        return handler.next(e);
      },
    ));
  }

  // --- AUTH ---
  Future<String?> login(String rut, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'rut': rut,
        'password': password,
      });
      final token = response.data['access_token'];
      final userId = response.data['userId']; 
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_id', userId);
      // Guardamos el RUT para usarlo en otras peticiones
      await prefs.setString('user_rut', rut);
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_rut');
  }

  Future<bool> register(String rut, String nombre, String email, String password) async {
    try {
      await _dio.post('/auth/register', data: {
        'rut': rut, 'nombre': nombre, 'email': email, 'password': password,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- CUENTAS ---
  Future<List<Cuenta>> getCuentas() async {
    try {
      final response = await _dio.get('/cuentas');
      final List<dynamic> data = response.data;
      return data.map((json) => Cuenta.fromJson(json)).toList();
    } catch (e) {
      print('Error al obtener cuentas: $e');
      return [];
    }
  }

  // --- TARJETAS ---
  Future<List<Tarjeta>> getTarjetas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('user_id'); // <-- CAMBIO CLAVE: Leemos el ID
      if (usuarioId == null) {
        throw Exception("Usuario no autenticado");
      }
      
      // <-- CAMBIO CLAVE: Usamos el endpoint correcto con el ID del usuario
      final response = await _dio.get('/tarjetas/$usuarioId'); 
      
      final List<dynamic> data = response.data;
      return data.map((json) => Tarjeta.fromJson(json)).toList();
    } catch (e) {
      print('Error al obtener tarjetas: $e');
      return [];
    }
  }

  Future<Tarjeta?> createTarjeta() async {
    try {
      final response = await _dio.post('/tarjetas');
      return Tarjeta.fromJson(response.data);
    } catch (e) {
      print('Error al crear tarjeta: $e');
      return null;
    }
  }

  Future<bool> deleteTarjeta(String tarjetaId) async {
    try {
      await _dio.delete('/tarjetas/$tarjetaId');
      return true;
    } catch (e) {
      print('Error al eliminar tarjeta: $e');
      return false;
    }
  }

  Future<bool> updateLimitesTarjeta(String tarjetaId, {double? montoDiario, double? montoSinAprobacion}) async {
    try {
      final Map<String, dynamic> data = {};
      if (montoDiario != null) data['monto_diario'] = montoDiario;
      if (montoSinAprobacion != null) data['compras_sin_aprobacion'] = montoSinAprobacion;
      
      await _dio.patch('/tarjetas/$tarjetaId/limites', data: data);
      return true;
    } catch (e) {
      print('Error al actualizar límites de tarjeta: $e');
      return false;
    }
  }
  
  // --- DESTINATARIOS ---
  Future<List<Destinatario>> getDestinatarios() async {
      try {
          final prefs = await SharedPreferences.getInstance();
          final rut = prefs.getString('user_rut');
          if (rut == null) return [];

          final response = await _dio.get('/destinatarios/$rut');
          final List<dynamic> data = response.data;
          return data.map((json) => Destinatario.fromJson(json)).toList();
      } catch (e) {
          print('Error al obtener destinatarios: $e');
          return [];
      }
  }

   Future<bool> deleteDestinatario(String destinatarioId) async {
    try {
      // El endpoint del backend es DELETE /destinatarios/:id
      await _dio.delete('/destinatarios/$destinatarioId');
      return true;
    } catch (e) {
      print('Error al eliminar destinatario: $e');
      return false;
    }
  }

  Future<Destinatario?> createDestinatario({
    required String alias,
    required String rutDestinatario,
    String? cuentaDestinoId, // Este campo es opcional en el DTO
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rutUsuario = prefs.getString('user_rut');
      if (rutUsuario == null) return null;

      // El payload debe coincidir con CreateDestinatarioDto
      final data = {
        'rut_usuario': rutUsuario,
        'alias': alias,
        'rut_destinatario': rutDestinatario,
      };
      // Solo añadimos la cuenta si se proporciona
      if (cuentaDestinoId != null) {
        data['cuenta_destino_id'] = cuentaDestinoId;
      }
      
      final response = await _dio.post('/destinatarios', data: data);
      return Destinatario.fromJson(response.data);
    } catch (e) {
      print('Error al crear destinatario: $e');
      return null;
    }
  }

  // --- TRANSACCIONES ---
  Future<String?> realizarTransferencia({
    required double monto,
    required String cuentaDestinoId,
  }) async {
    try {
      await _dio.post('/transacciones/transferir', data: {
        'monto': monto,
        'cuenta_destino_id': cuentaDestinoId,
      });
      // Si la petición es exitosa (código 2xx), devolvemos null para indicar éxito sin mensaje.
      return null;
    } on DioException catch (e) {
      // Si Dio captura una excepción (como un error 4xx o 5xx)
      print('Error al realizar transferencia: ${e.response?.data}');
      
      // Intentamos extraer el mensaje específico del backend.
      if (e.response?.data != null && e.response!.data is Map) {
        // La respuesta del backend es: { "message": "...", "error": "...", "statusCode": ... }
        return e.response!.data['message'] as String? ?? 'Error desconocido del servidor.';
      }
      
      // Si no podemos extraer el mensaje, devolvemos un error genérico.
      return 'Error de conexión o respuesta inesperada.';
    } catch (e) {
      // Para cualquier otro tipo de error no relacionado con Dio.
      print('Error inesperado: $e');
      return 'Ocurrió un error inesperado en la app.';
    }
  }

  Future<List<Transaccion>> getTransaccionesPendientes() async {
    try {
      final response = await _dio.get('/transacciones/pendientes');
      final List<dynamic> data = response.data;
      return data.map((json) => Transaccion.fromJson(json)).toList();
    } catch (e) {
      print('Error al obtener transacciones pendientes: $e');
      return [];
    }
  }

  Future<bool> aprobarRechazarTransaccion(String id, String accion) async {
    // accion puede ser 'aprobar' o 'rechazar'
    try {
      await _dio.post('/transacciones/$id/$accion');
      return true;
    } catch (e) {
      print('Error al $accion la transacción: $e');
      return false;
    }
  }

  Future<int> getConteoPendientes() async {
    try {
      final response = await _dio.get('/transacciones/pendientes/conteo');
      return (response.data['conteo'] as int?) ?? 0;
    } catch (e) {
      print('Error al obtener conteo de pendientes: $e');
      return 0;
    }
  }

  Future<List<Transaccion>> getHistorial({DateTime? fechaInicio, DateTime? fechaFin}) async {
    try {
      final Map<String, dynamic> queryParameters = {'page': 1};

      // Añadir fechas al query si no son nulas
      if (fechaInicio != null) {
        // Formato YYYY-MM-DD
        queryParameters['fechaInicio'] = fechaInicio.toIso8601String().substring(0, 10);
      }
      if (fechaFin != null) {
        queryParameters['fechaFin'] = fechaFin.toIso8601String().substring(0, 10);
      }

      final response = await _dio.get('/transacciones/historial', queryParameters: queryParameters);
      final List<dynamic> data = response.data;
      return data.map((json) => Transaccion.fromJson(json)).toList();
    } catch (e) {
      print('Error al obtener historial de transacciones: $e');
      return [];
    }
  }

  Future<bool> retirarDeAhorro(double monto) async {
    try {
      await _dio.post('/cuentas/retirar-ahorro', data: {
        'monto': monto,
      });
      return true;
    } catch (e) {
      print('Error al retirar de ahorro: $e');
      return false;
    }
  }
  

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
  
    Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> simularCompra({
    required double monto,
    required String numeroTarjeta,
    required String cvv,
    required String fechaVencimiento, // "MM/YY"
    required String pais,
    required DateTime fechaTransaccion,
  }) async {
    try {
      final data = {
        'monto': monto,
        'numero_tarjeta': numeroTarjeta,
        'cvv_tarjeta': cvv,
        'fecha_vencimiento_tarjeta': fechaVencimiento,
        'nombre_comercio': 'Laboratorio de Fraude',
        'pais': pais,
        'fecha_transaccion': fechaTransaccion.toIso8601String(),
      };
      
      final response = await _dio.post('/transacciones/comprar', data: data);
      return response.data as Map<String, dynamic>? ?? {'status': 'success', 'data': response.data};
    } on DioException catch (e) {
      // Si hay un error de Dio (como un 403 Forbidden o 400 Bad Request), devolvemos el cuerpo del error
      return e.response?.data as Map<String, dynamic>? ?? {'error': e.message};
    } catch (e) {
      return {'error': 'Ocurrió un error inesperado en la app.'};
    }
  }
}