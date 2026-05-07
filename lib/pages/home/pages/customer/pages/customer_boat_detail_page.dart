import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/disponibility_page.dart';

// Pantalla de detalle para el cliente.
// Recibe el barco seleccionado desde el listado y muestra su información completa.
class CustomerBoatDetailPage extends StatelessWidget {
  final BoatModel boat;

  const CustomerBoatDetailPage({super.key, required this.boat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(boat.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppTheme.detailBottomButtonPadding,
          child: ElevatedButton(
            style: AppTheme.accentButtonStyle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DisponibilityPage(boat: boat)),
            ),
            child: Text(
              'Mirar Disponibilidad',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.pearlWhite,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal del barco. Si falla o está vacía, se muestra un placeholder.
            boat.imageUrl.isNotEmpty
                ? Image.network(
                    boat.imageUrl,
                    height: AppTheme.detailImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _DetailImagePlaceholder(),
                  )
                : const _DetailImagePlaceholder(),

            Padding(
              padding: AppTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boat.name,
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    boat.category.isEmpty ? 'Sin categoría' : boat.category,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),

                  Text(
                    '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.sunsetGold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),

                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppTheme.oceanBlue,
                        size: AppTheme.iconSizeLarge,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Capacidad: ${boat.capacity} personas',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.deepNavy,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  Text(
                    'Descripción',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),

                  Text(
                    boat.description.isEmpty
                        ? 'Sin descripción disponible.'
                        : boat.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                      height: AppTheme.lineHeightInfo,
                    ),
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
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.detailImageHeight,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: AppTheme.detailPlaceholderIconSize,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Imagen no disponible',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
          ),
        ],
      ),
    );
  }
}
