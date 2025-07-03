import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../models/tarjeta.dart'; // <-- IMPORTAR MODELO DE TARJETA

class FraudTestScreen extends StatefulWidget {
  const FraudTestScreen({super.key});

  @override
  State<FraudTestScreen> createState() => _FraudTestScreenState();
}

class _FraudTestScreenState extends State<FraudTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // <<< ESTADO PARA LAS TARJETAS >>>
  late Future<List<Tarjeta>> _tarjetasFuture;
  Tarjeta? _selectedTarjeta;

  // Controladores para los datos que no se seleccionan
  final _montoController = TextEditingController(text: '10000');
  
  // Estado para los selectores de fraude
  String _selectedPais = 'Chile';
  DateTime _selectedDateTime = DateTime.now().toUtc();
  
  // Estado de la UI
  Map<String, dynamic>? _resultado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargamos las tarjetas del usuario al iniciar la pantalla
    _tarjetasFuture = _api.getTarjetas();
  }

  Future<void> _selectDateTime() async {
    // ... (este método no cambia)
  }

  void _simularCompra() async {
    // Validamos que se haya seleccionado una tarjeta
    if (_selectedTarjeta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una tarjeta.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; _resultado = null; });
    
    final resultado = await _api.simularCompra(
      monto: double.parse(_montoController.text),
      numeroTarjeta: _selectedTarjeta!.numero,
      cvv: _selectedTarjeta!.cvv,
      fechaVencimiento: _selectedTarjeta!.fechaVencimiento,
      pais: _selectedPais,
      fechaTransaccion: _selectedDateTime, 
    );
    
    if(mounted) {
      setState(() { _isLoading = false; _resultado = resultado; });
      if (resultado.containsKey('transaccionId')) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio de Fraude')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Seleccionar Tarjeta', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              // <<< WIDGET MEJORADO PARA SELECCIONAR TARJETA >>>
              FutureBuilder<List<Tarjeta>>(
                future: _tarjetasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No se encontraron tarjetas o hubo un error.');
                  }
                  
                  final tarjetas = snapshot.data!;
                  return DropdownButtonFormField<Tarjeta>(
                    value: _selectedTarjeta,
                    hint: const Text('Selecciona una tarjeta para la prueba'),
                    isExpanded: true,
                    items: tarjetas.map((tarjeta) {
                      // Mostramos los últimos 4 dígitos para identificarla
                      final ultimos4 = tarjeta.numero.substring(tarjeta.numero.length - 4);
                      return DropdownMenuItem(
                        value: tarjeta,
                        child: Text('Tarjeta terminada en ....$ultimos4'),
                      );
                    }).toList(),
                    onChanged: (tarjeta) {
                      setState(() {
                        _selectedTarjeta = tarjeta;
                      });
                    },
                    validator: (value) => value == null ? 'Debes seleccionar una tarjeta' : null,
                  );
                },
              ),

              const Divider(height: 40),
              Text('Parámetros de Simulación', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto de la Compra', prefixText: '\$'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Monto inválido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPais,
                items: ['Chile', 'Brasil', 'USA', 'Otro'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _selectedPais = v!),
                decoration: const InputDecoration(labelText: 'País de la Transacción'),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Fecha y Hora de la Transacción'),
                subtitle: Text(DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(_selectedDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _simularCompra,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Simular Compra'),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 24),
                Text('Resultado de la Simulación:', style: Theme.of(context).textTheme.titleMedium),
                Card(
                  color: _resultado!.containsKey('error') ? Colors.red.shade100 : Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(_resultado.toString()),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}