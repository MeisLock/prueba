import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:table_calendar/table_calendar.dart';

// Pantalla de detalle para el cliente.
// Recibe el barco seleccionado desde el listado y muestra su información completa.
class CustomerBoatDetailPage extends StatefulWidget {
  final BoatModel boat;

  const CustomerBoatDetailPage({super.key, required this.boat});

  @override
  State<CustomerBoatDetailPage> createState() => _CustomerBoatDetailPageState();
}

class _CustomerBoatDetailPageState extends State<CustomerBoatDetailPage> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  final List<DateTime> _unavailableDates = [
    DateTime(2026, 5, 5),
    DateTime(2026, 5, 6),
    DateTime(2026, 5, 10),
  ];

  bool _isUnavailable(DateTime day) {
    return _unavailableDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  bool _rangeHasUnavailableDates(DateTime start, DateTime end) {
    DateTime current = start;
    while (current.isBefore(end) || isSameDay(current, end)) {
      if (_isUnavailable(current)) return true;
      current = current.add(const Duration(days: 1));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final boat = widget.boat;
    return Scaffold(
      appBar: AppBar(title: Text(boat.name)),
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
                  _BoatDetailInfoItem(
                    icon: Icons.directions_boat_outlined,
                    label: _formatBoatCategory(boat.category),
                  ),
                  const SizedBox(height: AppTheme.spacing12),

                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppTheme.oceanBlue,
                        size: AppTheme.iconSizeLarge,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                  const SizedBox(height: AppTheme.spacing24),

                  Text(
                    'Disponibilidad',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing12),

                  // Calendario integrado en el detalle del barco para seleccionar fechas de reserva.
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    enabledDayPredicate: (day) => !_isUnavailable(day),
                    onRangeSelected: (start, end, focusedDay) {
                      if (start != null &&
                          end != null &&
                          _rangeHasUnavailableDates(start, end)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El rango contiene fechas no disponibles',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _rangeStart = start;
                        _rangeEnd = end;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      disabledBuilder: (context, day, focusedDay) {
                        if (_isUnavailable(day)) {
                          return Container(
                            margin: const EdgeInsets.all(6),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppTheme.alertRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: AppTheme.pearlWhite,
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.all(6),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundDim,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                    headerStyle: AppTheme.calendarHeaderStyle,
                    daysOfWeekStyle: AppTheme.calendarDaysOfWeekStyle,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.oceanBlue.withValues(
                          alpha: AppTheme.alphaOverlay,
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(color: AppTheme.deepNavy),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.oceanBlue,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: AppTheme.pearlWhite,
                      ),
                      disabledDecoration: const BoxDecoration(
                        color: AppTheme.backgroundDim,
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                      rangeStartDecoration: const BoxDecoration(
                        color: AppTheme.oceanBlue,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: const BoxDecoration(
                        color: AppTheme.oceanBlue,
                        shape: BoxShape.circle,
                      ),
                      withinRangeDecoration: BoxDecoration(
                        color: AppTheme.sunsetGold.withValues(
                          alpha: AppTheme.alphaMedium,
                        ),
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: AppTheme.deepNavy,
                      ),
                      weekendDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: const TextStyle(
                        color: AppTheme.oceanBlue,
                      ),
                      outsideDaysVisible: false,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _rangeStart == null
                          ? null
                          : () {
                              // TODO: conectar con el flujo de reserva
                            },
                      style: AppTheme.accentButtonStyle,
                      child: Text(
                        'Reservar',
                        style: AppTheme.buttonTextStyle.copyWith(
                          color: AppTheme.pearlWhite,
                        ),
                      ),
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

class _BoatDetailInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BoatDetailInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppTheme.iconSizeLarge, color: AppTheme.oceanBlue),
        const SizedBox(width: AppTheme.spacing8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textMuted),
          ),
        ),
      ],
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
