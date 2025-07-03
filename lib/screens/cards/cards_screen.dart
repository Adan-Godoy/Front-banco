// lib/screens/cards/cards_screen.dart
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/tarjeta.dart';
import '../../widgets/virtual_card_widget.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Tarjeta>> _tarjetasFuture;
  bool _isProcessing = false; // Estado de carga unificado

  @override
  void initState() {
    super.initState();
    _fetchTarjetas();
  }

  void _fetchTarjetas() {
    setState(() {
      _tarjetasFuture = _apiService.getTarjetas();
    });
  }

  Future<void> _handleDelete(String tarjetaId) async {
    setState(() => _isProcessing = true);
    final success = await _apiService.deleteTarjeta(tarjetaId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Tarjeta eliminada con éxito.' : 'Error al eliminar la tarjeta.')),
      );
      if (success) {
        _fetchTarjetas(); // Recargar la lista si se eliminó correctamente
      }
    }
    setState(() => _isProcessing = false);
  }

  void _generateNewCard(int currentCardCount) async {
    if (currentCardCount >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Límite de 20 tarjetas alcanzado.')));
      return;
    }
    setState(() => _isProcessing = true);
    final newCard = await _apiService.createTarjeta();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newCard != null ? '¡Nueva tarjeta virtual creada!' : 'Error al crear la tarjeta.')),
      );
      if (newCard != null) _fetchTarjetas();
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Tarjeta>>(
      future: _tarjetasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar tarjetas: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // ... (UI para cuando no hay tarjetas, sin cambios)
        }

        final tarjetas = snapshot.data!;
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: tarjetas.length,
                    itemBuilder: (context, index) {
                      return VirtualCardWidget(
                        tarjeta: tarjetas[index],
                        onDelete: _handleDelete,
                        onReload: _fetchTarjetas,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _isProcessing ? null : () => _generateNewCard(tarjetas.length),
                    child: const Text('Generar Nueva Tarjeta'),
                  ),
                ),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}