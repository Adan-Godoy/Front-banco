// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

  Future<String?> login(String rut, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'rut': rut,
        'password': password,
      });

      final token = response.data['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return token;
    } on DioException catch (e) {
      print('Error al iniciar sesión: ${e.response?.data}');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> register(String rut, String nombre, String email, String password) async {
    try {
      await _dio.post('/auth/register', data: {
        'rut': rut,
        'nombre': nombre,
        'email': email,
        'password': password,
      });
      return true;
    } on DioException catch (e) {
      print('Error en registro: ${e.response?.data}');
      return false;
    }
  }
}
