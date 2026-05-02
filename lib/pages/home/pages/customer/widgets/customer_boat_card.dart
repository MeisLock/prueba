import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_boat_detail_page.dart';

class CustomerBoatCard extends StatelessWidget {
  final BoatModel boat;

  const CustomerBoatCard({
    super.key,
    required this.boat,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),

      // Al pulsar la tarjeta se abre la pantalla de detalle del barco.
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerBoatDetailPage(boat: boat),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppTheme.deepNavy.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: boat.imageUrl.isNotEmpty
                  ? Image.network(
                      boat.imageUrl,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _BoatImagePlaceholder(
                        name: boat.name,
                      ),
                    )
                  : _BoatImagePlaceholder(name: boat.name),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boat.name,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_boat_outlined,
                        size: 18,
                        color: AppTheme.oceanBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          boat.category.isEmpty ? 'Sin categoría' : boat.category,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Text(
                        '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                        style: textTheme.titleMedium?.copyWith(
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

class _BoatImagePlaceholder extends StatelessWidget {
  final String name;

  const _BoatImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: 42,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}