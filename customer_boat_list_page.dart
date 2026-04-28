import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat.dart';
import 'package:ocean_rent/pages/home/pages/customer/widgets/customer_boat_card.dart';
import 'package:ocean_rent/services/boat_service.dart';

class CustomerBoatListPage extends StatelessWidget {
  const CustomerBoatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<Boat>>(
      stream: BoatService.instance.getBoats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error cargando barcos:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.deepNavy),
          );
        }

        final boats = snapshot.data ?? [];

        if (boats.isEmpty) {
          return Center(
            child: Text(
              'No hay barcos disponibles',
              style: textTheme.bodyLarge?.copyWith(
                color: AppTheme.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: boats.length,
          itemBuilder: (context, index) {
            final boat = boats[index];
            return CustomerBoatCard(boat: boat);
          },
        );
      },
    );
  }
}