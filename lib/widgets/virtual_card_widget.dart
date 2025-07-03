// lib/widgets/virtual_card_widget.dart
import 'package:flutter/material.dart';
import '../models/tarjeta.dart';
import '../screens/cards/card_settings_screen.dart'; 

class VirtualCardWidget extends StatefulWidget {
  final Tarjeta tarjeta;
  // <<< Callbacks para las acciones >>>
  final VoidCallback onReload;
  final Future<void> Function(String) onDelete;

  const VirtualCardWidget({
    super.key,
    required this.tarjeta,
    required this.onReload,
    required this.onDelete,
  });

  @override
  State<VirtualCardWidget> createState() => _VirtualCardWidgetState();
}

class _VirtualCardWidgetState extends State<VirtualCardWidget> {
  bool _showData = false;

  String _formatCardNumber(String number) {
    if (number.length != 16) return number;
    if (_showData) {
      // Mostrar número con espacios
      return '${number.substring(0, 4)} ${number.substring(4, 8)} ${number.substring(8, 12)} ${number.substring(12, 16)}';
    }
    // Mostrar número enmascarado
    return '**** **** **** ${number.substring(12)}';
  }

  void _confirmAndDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta tarjeta de forma permanente?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.onDelete(widget.tarjeta.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF004481), Color(0xFF0055A4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            // --- PARTE SUPERIOR DE LA TARJETA ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(alignment: Alignment.topRight, child: Text('VISA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
                const SizedBox(height: 30),
                Text(_formatCardNumber(widget.tarjeta.numero), style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontFamily: 'monospace')),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expira', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(widget.tarjeta.fechaVencimiento, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CVV', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_showData ? widget.tarjeta.cvv : '***', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                )
              ],
            ),
            const Divider(color: Colors.white30, height: 30),
            // --- BOTONES DE ACCIÓN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showData = !_showData),
                  icon: Icon(_showData ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                  label: Text(_showData ? 'Ocultar' : 'Ver datos', style: const TextStyle(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context, 
                      MaterialPageRoute(builder: (ctx) => CardSettingsScreen(tarjeta: widget.tarjeta))
                    );
                    if (result == true) {
                      widget.onReload(); // Llama al callback para recargar
                    }
                  },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  label: const Text('Configurar', style: TextStyle(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: _confirmAndDelete,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}