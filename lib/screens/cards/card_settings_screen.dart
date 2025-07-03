// lib/screens/cards/card_settings_screen.dart
import 'package:flutter/material.dart';
import '../../models/tarjeta.dart';
import '../../api/api_service.dart';

class CardSettingsScreen extends StatefulWidget {
  final Tarjeta tarjeta;

  const CardSettingsScreen({super.key, required this.tarjeta});

  @override
  State<CardSettingsScreen> createState() => _CardSettingsScreenState();
}

class _CardSettingsScreenState extends State<CardSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  late TextEditingController _montoSinAprobacionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Asumimos que el modelo Tarjeta tendrá los límites
    
    _montoSinAprobacionController = TextEditingController(text: widget.tarjeta.limiteSinAprobacion.toString());
  }

  void _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      
      final double? montoSinAprobacion = double.tryParse(_montoSinAprobacionController.text);

      final success = await _apiService.updateLimitesTarjeta(
        widget.tarjeta.id,
        
        montoSinAprobacion: montoSinAprobacion,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Límites actualizados con éxito.' : 'Error al actualizar los límites.')),
        );
        if (success) {
          Navigator.of(context).pop(true); // Devolvemos 'true' para indicar que se debe recargar
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Límites de Tarjeta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarjeta terminada en ${widget.tarjeta.numero.substring(12)}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
             
              const SizedBox(height: 24),
              TextFormField(
                controller: _montoSinAprobacionController,
                decoration: const InputDecoration(labelText: 'Compra máxima sin aprobación', prefixText: '\$ '),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) < 0) ? 'Monto inválido' : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar Cambios'),
              )
            ],
          ),
        ),
      ),
    );
  }
}