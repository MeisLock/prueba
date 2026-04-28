import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat.dart';

// Pantalla de detalle para el cliente.
// Recibe el barco seleccionado desde el listado y muestra su información completa.
class CustomerBoatDetailPage extends StatelessWidget {
  final Boat boat;

  const CustomerBoatDetailPage({
    super.key,
    required this.boat,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(boat.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal del barco. Si falla o está vacía, se muestra un placeholder.
            boat.imageUrl.isNotEmpty
                ? Image.network(
                    boat.imageUrl,
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _DetailImagePlaceholder(name: boat.name),
                  )
                : _DetailImagePlaceholder(name: boat.name),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boat.name,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    boat.type.isEmpty ? 'Sin categoría' : boat.type,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.people_outline),
                      const SizedBox(width: 8),
                      Text('Capacidad: ${boat.capacity} personas'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Descripción',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    boat.description.isEmpty
                        ? 'Sin descripción disponible.'
                        : boat.description,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder reutilizado cuando no existe imagen o la URL no carga correctamente.
class _DetailImagePlaceholder extends StatelessWidget {
  final String name;

  const _DetailImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: 56,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: 8),
          Text(
            'Imagen no disponible',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}