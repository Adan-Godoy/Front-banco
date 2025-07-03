import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../models/destinatario.dart';
import 'add_recipient_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  // Servicios y Controladores
  final ApiService _apiService = ApiService();
  final _montoTransferController = TextEditingController();
  final _montoAhorroController = TextEditingController();

  // Claves para validación de formularios
  final _transferFormKey = GlobalKey<FormState>();
  final _ahorroFormKey = GlobalKey<FormState>();

  // Estado de la UI
  late Future<List<Destinatario>> _destinatariosFuture;
  Destinatario? _selectedDestinatario;
  bool _isProcessing = false; // Estado de carga unificado
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDestinatarios();
  }

  void _loadDestinatarios() {
    setState(() {
      _selectedDestinatario = null;
      _destinatariosFuture = _apiService.getDestinatarios();
    });
  }

  // --- NAVEGACIÓN Y ACCIONES DE DESTINATARIOS ---

  Future<void> _addRecipient() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipientScreen()),
    );
    if (result == true) {
      _loadDestinatarios();
    }
  }

  void _handleDeleteRecipient() async {
    if (_selectedDestinatario == null) return;
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar a "${_selectedDestinatario!.alias}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isDeleting = true);
      final success = await _apiService.deleteDestinatario(_selectedDestinatario!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Destinatario eliminado con éxito.' : 'Error al eliminar el destinatario.')),
        );
        if (success) _loadDestinatarios();
      }
      setState(() => _isDeleting = false);
    }
  }

  // --- LÓGICA DE OPERACIONES ---

  void _handleTransfer() async {
    if (_transferFormKey.currentState?.validate() ?? false) {
      if (_selectedDestinatario?.cuentaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de destinatario.')));
        return;
      }

      setState(() => _isProcessing = true);
      final monto = double.tryParse(_montoTransferController.text);

      // El método ahora devuelve un String? con el mensaje de error, o null si fue exitoso.
      final String? errorMessage = await _apiService.realizarTransferencia(
        monto: monto!,
        cuentaDestinoId: _selectedDestinatario!.cuentaId!,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        if (errorMessage == null) {
          // Si no hay mensaje de error, la operación fue exitosa.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Transferencia realizada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Devuelve true para recargar
        } else {
          // Si hay un mensaje de error, lo mostramos.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleRetiroAhorro() async {
    if (_ahorroFormKey.currentState?.validate() ?? false) {
      setState(() => _isProcessing = true);
      final monto = double.tryParse(_montoAhorroController.text);

      final success = await _apiService.retirarDeAhorro(monto!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Monto movido a Cuenta Principal con éxito.' : 'Error al retirar de ahorro.')),
        );
        if (success) Navigator.pop(context, true);
      }
      setState(() => _isProcessing = false);
    }
  }


  // --- CONSTRUCCIÓN DE LA UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realizar Operaciones')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            _buildTransferSection(),
            const Divider(height: 60, thickness: 1, indent: 20, endIndent: 20),
            _buildAhorroSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferSection() {
    return Form(
      key: _transferFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transferir a Terceros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          FutureBuilder<List<Destinatario>>(
            future: _destinatariosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LinearProgressIndicator());
              }
              final destinatarios = snapshot.data ?? [];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Destinatario>(
                      value: _selectedDestinatario,
                      hint: const Text('Selecciona un destinatario'),
                      isExpanded: true,
                      items: destinatarios.map((dest) => DropdownMenuItem(value: dest, child: Text(dest.alias))).toList(),
                      onChanged: (value) => setState(() => _selectedDestinatario = value),
                      validator: (value) => value == null ? 'Selecciona un destinatario' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: (_selectedDestinatario != null && !_isDeleting) ? _handleDeleteRecipient : null,
                    tooltip: 'Eliminar destinatario',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Agregar Destinatario'),
              onPressed: _addRecipient,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _montoTransferController,
            decoration: const InputDecoration(labelText: 'Monto a transferir', prefixText: '\$ '),
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Ingresa un monto válido' : null,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleTransfer,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Transferir'),
          )
        ],
      ),
    );
  }

  Widget _buildAhorroSection() {
    return Form(
      key: _ahorroFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mover desde Ahorro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _montoAhorroController,
            decoration: const InputDecoration(labelText: 'Monto a mover a Cta. Principal', prefixText: '\$ '),
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Ingresa un monto válido' : null,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleRetiroAhorro,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green),
            child: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Mover a Cuenta Principal'),
          )
        ],
      ),
    );
  }
}