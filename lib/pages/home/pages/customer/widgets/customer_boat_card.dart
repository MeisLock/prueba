import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_boat_detail_page.dart';

class CustomerBoatCard extends StatelessWidget {
  final BoatModel boat;

  const CustomerBoatCard({super.key, required this.boat});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppTheme.borderRadiusCard,
      // Al pulsar la tarjeta se abre la pantalla de detalle del barco.
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerBoatDetailPage(boat: boat)),
        );
      },

      child: Container(
        margin: AppTheme.cardBottomMargin,
        decoration: AppTheme.cardDecoration(
          color: AppTheme.surface,
          radius: AppTheme.radiusCard,
          border: Border.all(
            color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
          ),
          boxShadow: AppTheme.softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppTheme.borderRadiusCardTop,
              child: boat.imageUrl.isNotEmpty
                  ? Image.network(
                      boat.imageUrl,
                      height: AppTheme.customerBoatImageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _BoatImagePlaceholder(name: boat.name),
                    )
                  : _BoatImagePlaceholder(name: boat.name),
            ),
            Padding(
              padding: AppTheme.compactCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boat.name,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BoatInfoItem(
                              icon: Icons.directions_boat_outlined,
                              label: _formatBoatCategory(boat.category),
                            ),
                            const SizedBox(height: AppTheme.spacing6),
                            _BoatInfoItem(
                              icon: Icons.location_on_outlined,
                              label: boat.portName.trim().isEmpty
                                  ? 'Sin ubicación'
                                  : boat.portName.trim(),
                            ),
                            const SizedBox(height: AppTheme.spacing6),
                            _BoatInfoItem(
                              icon: Icons.people_outline,
                              label: boat.capacity <= 0
                                  ? 'Sin capacidad'
                                  : boat.capacity == 1
                                  ? '1 persona'
                                  : '${boat.capacity} personas',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing10),
                      Text(
                        '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

String _formatBoatCategory(String category) {
  final normalizedCategory = category.trim().toLowerCase();

  switch (normalizedCategory) {
    case 'lancha':
      return 'Lancha';
    case 'semirigida':
      return 'Semirrígida';
    case 'velero':
      return 'Velero';
    case 'yate':
      return 'Yate';
    case 'catamaran':
      return 'Catamarán';
    case 'jetski':
      return 'Jet Ski';
    default:
      return category.trim().isEmpty ? 'Sin categoría' : category.trim();
  }
}

class _BoatInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BoatInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppTheme.iconSizeMedium, color: AppTheme.oceanBlue),
        const SizedBox(width: AppTheme.spacing6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }
}

class _BoatImagePlaceholder extends StatelessWidget {
  final String name;

  const _BoatImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.customerBoatImageHeight,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: AppTheme.emptyStateIconSize,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
