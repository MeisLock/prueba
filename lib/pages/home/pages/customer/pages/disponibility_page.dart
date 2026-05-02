import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/login/login_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
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
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).currentUser;
    final isAnonymous = user == null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.boat.name,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
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
                      const SnackBar(content: Text('El rango contiene fechas no disponibles')),
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
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: textTheme.titleLarge!.copyWith(
                    color: AppTheme.deepNavy,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: AppTheme.deepNavy,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.deepNavy,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: textTheme.bodySmall!.copyWith(color: AppTheme.deepNavy, fontWeight: FontWeight.bold,),
                  weekendStyle: textTheme.bodySmall!.copyWith(color: AppTheme.oceanBlue,fontWeight: FontWeight.bold,),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: AppTheme.oceanBlue.withValues(alpha: 0.4), shape: BoxShape.circle,),
                  todayTextStyle: const TextStyle(color: AppTheme.deepNavy),
                  selectedDecoration: const BoxDecoration(color: AppTheme.deepNavy,shape: BoxShape.circle,),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  disabledDecoration: BoxDecoration(color: Colors.grey.shade300,shape: BoxShape.circle,),
                  disabledTextStyle: TextStyle(color: Colors.grey.shade500),
                  defaultDecoration: const BoxDecoration(shape: BoxShape.circle,),
                  defaultTextStyle: const TextStyle(color: AppTheme.deepNavy),
                  weekendDecoration: const BoxDecoration(shape: BoxShape.circle,),
                  weekendTextStyle: TextStyle(color: AppTheme.oceanBlue),
                  outsideDaysVisible: false,
                ),
              ),

              if (_rangeStart != null) ...[
                const SizedBox(height: 24),
                Text(
                  _rangeEnd == null
                  ? 'Fecha seleccionada: ${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year}'
                  : 'Fecha seleccionada:Del ${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year}',
                  style: textTheme.bodyLarge,
                ),
                if (_rangeEnd != null)
                Text('al ${_rangeEnd!.day}/${_rangeEnd!.month}/${_rangeEnd!.year}',
                style: textTheme.bodyLarge,
                )
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _rangeStart == null
                ? null
                : () {
                    if (isAnonymous) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    } else {
                      // Añadir el flujo de reserva
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepNavy,
              foregroundColor: AppTheme.pearlWhite,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isAnonymous ? 'Inicia sesión para reservar' : 'Reservar',
              style: textTheme.bodyLarge?.copyWith(
                color: AppTheme.pearlWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}