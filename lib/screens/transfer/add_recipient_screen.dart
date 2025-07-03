// lib/screens/transfer/add_recipient_screen.dart
import 'package:flutter/material.dart';
import '../../api/api_service.dart';

class AddRecipientScreen extends StatefulWidget {
  const AddRecipientScreen({super.key});

  @override
  State<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends State<AddRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

final _aliasController = TextEditingController();
final _rutController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final success = await _apiService.createDestinatario(
        alias: _aliasController.text,
        rutDestinatario: _rutController.text,
        // La cuenta de destino la podrías pedir en otro campo si quisieras.
        // Por simplicidad, lo dejamos fuera.
      );

      setState(() => _isLoading = false);

      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destinatario agregado con éxito')),
        );
        Navigator.pop(context, true); // Devuelve 'true' para indicar éxito
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agregar destinatario')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Destinatario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(labelText: 'Alias (Ej: Papá, Arriendo)'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rutController,
                decoration: const InputDecoration(labelText: 'Rut del Destinatario'),
                 validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Guardar Destinatario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}