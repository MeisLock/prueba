import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/widgets/app_navigator.dart';
import 'package:table_calendar/table_calendar.dart';

class DisponibilityPage extends ConsumerStatefulWidget {
  final BoatModel boat;

  const DisponibilityPage({super.key, required this.boat});

  @override
  ConsumerState<DisponibilityPage> createState() => _DisponibilityPageState();
}

class _DisponibilityPageState extends ConsumerState<DisponibilityPage> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  // Fechas de prueba elimianar una vez implementadas la logica de reserva
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
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).currentUser;
    final isAnonymous = user == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.listPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.boat.name,
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.deepNavy,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                onRangeSelected: (start, end, focusedDay) {
                  if (end != null && _rangeHasUnavailableDates(start!, end)) {
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
                enabledDayPredicate: (day) => !_isUnavailable(day),
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: AppTheme.calendarHeaderStyle,
                daysOfWeekStyle: AppTheme.calendarDaysOfWeekStyle,
                calendarStyle: AppTheme.calendarStyle,
              ),
              if (_rangeStart != null) ...[
                const SizedBox(height: AppTheme.spacing24),
                Text(
                  _rangeEnd == null
                      ? 'Fecha seleccionada: ${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year}'
                      : 'Fecha seleccionada: Del ${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year}',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.deepNavy),
                ),
                if (_rangeEnd != null)
                  Text(
                    'al ${_rangeEnd!.day}/${_rangeEnd!.month}/${_rangeEnd!.year}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppTheme.detailBottomButtonPadding,
          child: ElevatedButton(
            onPressed: _rangeStart == null
                ? null
                : () {
                    if (isAnonymous) {
                      AppNavigator.goToLogin(context);
                    } else {
                      // Añadir el flujo de reserva
                    }
                  },
            style: AppTheme.fullWidthPrimaryButtonStyle,
            child: Text(
              isAnonymous ? 'Inicia sesión para reservar' : 'Reservar',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.pearlWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
