import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_calendar_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_profile_screen.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/boat_form_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/widgets/admin_empty_section.dart';
import 'package:ocean_rent/pages/home/pages/admin/widgets/admin_quick_action_card.dart';
import 'package:ocean_rent/pages/home/pages/admin/widgets/admin_summary_card.dart';
import 'package:ocean_rent/pages/onboarding/onboarding_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/boat_providers.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  Future<void> _deleteBoat(
    BuildContext context,
    WidgetRef ref,
    BoatModel boat,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar barco'),
        content: Text('¿Seguro que quieres eliminar "${boat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.deepNavy)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(boatRepositoryProvider).deleteBoat(boat.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barco eliminado correctamente')),
      );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider).signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin - Barcos'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.deepNavy,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BoatFormPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Barco'),
      ),
      body: ref
          .watch(boatsStreamProvider)
          .when(
            loading: () => Center(
              child: CircularProgressIndicator(color: AppTheme.deepNavy),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error cargando el panel:\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (boats) {
              return _AdminDashboard(
                boats: boats,
                onCreateBoat: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BoatFormPage()),
                  );
                },
                onEditBoat: (boat) async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BoatFormPage(boat: boat)),
                  );
                },
                onDeleteBoat: (boat) => _deleteBoat(context, ref, boat),
              );
            },
          ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final List<BoatModel> boats;
  final VoidCallback onCreateBoat;
  final ValueChanged<BoatModel> onEditBoat;
  final ValueChanged<BoatModel> onDeleteBoat;

  const _AdminDashboard({
    required this.boats,
    required this.onCreateBoat,
    required this.onEditBoat,
    required this.onDeleteBoat,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        _AdminHeader(totalBoats: boats.length),
        const SizedBox(height: 20),

        _SectionTitle(
          title: 'Resumen de actividad',
          subtitle: 'Estado general del panel de administración.',
        ),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            AdminSummaryCard(
              title: 'Reservas próximas',
              value: '0',
              subtitle: 'Pendiente de bookings',
              icon: Icons.calendar_month_outlined,
              color: AppTheme.oceanBlue,
            ),
            AdminSummaryCard(
              title: 'Fianzas pendientes',
              value: '0 €',
              subtitle: 'Pendiente de Stripe',
              icon: Icons.payments_outlined,
              color: AppTheme.sunsetGold,
            ),
            AdminSummaryCard(
              title: 'Barcos registrados',
              value: '${boats.length}',
              subtitle: 'Datos reales de boats',
              icon: Icons.directions_boat_filled_outlined,
              color: AppTheme.deepNavy,
            ),
            AdminSummaryCard(
              title: 'Titulaciones',
              value: '0',
              subtitle: 'Pendiente de users',
              icon: Icons.verified_user_outlined,
              color: AppTheme.alertRed,
            ),
          ],
        ),

        const SizedBox(height: 26),

        _SectionTitle(
          title: 'Accesos rápidos',
          subtitle: 'Acciones principales del administrador.',
        ),
        const SizedBox(height: 12),

        AdminQuickActionCard(
          title: 'Pedidos / reservas',
          subtitle: 'Consultar solicitudes de alquiler.',
          icon: Icons.assignment_outlined,
          color: AppTheme.oceanBlue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reservas se conectará en una próxima tarea.'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        AdminQuickActionCard(
          title: 'Calendario',
          subtitle: 'Ver disponibilidad y bloqueos.',
          icon: Icons.calendar_month_outlined,
          color: AppTheme.deepNavy,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminCalendarPage()),
            );
          },
        ),
        const SizedBox(height: 12),

        AdminQuickActionCard(
          title: 'Mantenimiento',
          subtitle: 'Bloquear fechas por revisión o avería.',
          icon: Icons.build_outlined,
          color: AppTheme.sunsetGold,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Mantenimiento se conectará en una próxima tarea.',
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 26),

        _SectionTitle(
          title: 'Pedidos recientes',
          subtitle: 'Preparado para conectarse con la colección bookings.',
        ),
        const SizedBox(height: 12),

        AdminEmptySection(
          icon: Icons.event_note_outlined,
          title: 'No hay reservas conectadas todavía',
          message:
              'Cuando se implemente bookings, aquí aparecerán los pedidos recientes.',
        ),

        const SizedBox(height: 26),

        _SectionTitle(
          title: 'Gestión de flota',
          subtitle: 'CRUD de barcos disponible desde el panel.',
          trailing: TextButton.icon(
            onPressed: onCreateBoat,
            icon: const Icon(Icons.add),
            label: const Text('Crear barco'),
          ),
        ),
        const SizedBox(height: 12),

        if (boats.isEmpty)
          AdminEmptySection(
            icon: Icons.directions_boat_filled_outlined,
            title: 'No hay barcos registrados',
            message:
                'Crea el primer barco para empezar a completar el catálogo.',
            buttonText: 'Crear barco',
            onPressed: onCreateBoat,
          )
        else
          ...boats.map(
            (boat) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BoatAdminCard(
                boat: boat,
                onEdit: () => onEditBoat(boat),
                onDelete: () => onDeleteBoat(boat),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final int totalBoats;

  const _AdminHeader({required this.totalBoats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.deepNavy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel del Admin',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control de reservas, calendario, flota y titulaciones.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalBoats',
                style: textTheme.titleLarge?.copyWith(
                  color: AppTheme.sunsetGold,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'barcos',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _BoatAdminCard extends StatelessWidget {
  final BoatModel boat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BoatAdminCard({
    required this.boat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = boat.imageUrl.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.deepNavy.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return _BoatImagePlaceholder(name: boat.name);
                    },
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.directions_boat_outlined,
                      label: _formatCategory(boat.category),
                    ),
                    _InfoChip(
                      icon: Icons.people_alt_outlined,
                      label: '${boat.capacity} personas',
                    ),
                    _InfoChip(
                      icon: Icons.euro_outlined,
                      label: '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  boat.description.trim().isEmpty
                      ? 'Sin descripción'
                      : boat.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.deepNavy,
                          side: BorderSide(
                            color: AppTheme.deepNavy.withValues(alpha: 0.25),
                          ),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.alertRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String value) {
    switch (value.trim().toLowerCase()) {
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
        return value.isEmpty ? 'Sin categoría' : value;
    }
  }
}

class _BoatImagePlaceholder extends StatelessWidget {
  final String name;

  const _BoatImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: 48,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: 10),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.oceanBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.oceanBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.deepNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
