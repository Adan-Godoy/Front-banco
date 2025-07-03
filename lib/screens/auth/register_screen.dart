// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:front_sistema_bancario/api/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController rutController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  bool isLoading = false;
  String? error;
  String? success;

  void register() async {
    setState(() {
      isLoading = true;
      error = null;
      success = null;
    });

    final registered = await apiService.register(
      rutController.text,
      nombreController.text,
      emailController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (registered) {
      setState(() {
        success = 'Registro exitoso. Ahora puedes iniciar sesión.';
      });

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    } else {
      setState(() {
        error = 'Error al registrarse. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: rutController,
              decoration: const InputDecoration(labelText: 'RUT'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : register,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Registrarse'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            if (success != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(success!, style: const TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}
