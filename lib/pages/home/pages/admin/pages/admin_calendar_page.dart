import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminCalendarPage extends ConsumerStatefulWidget {
  const AdminCalendarPage({super.key});

  @override
  ConsumerState<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends ConsumerState<AdminCalendarPage> {
  String? _selectedBoatId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _changeSelectedBoat(String? boatId) {
    setState(() {
      _selectedBoatId = boatId;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _saveSelectedRange() {
    if (_selectedBoatId == null || _rangeStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un barco y una fecha.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Calendario preparado. La conexión con maintenance_blocks se hará en una próxima tarea.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boatsAsync = ref.watch(boatsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de flota')),
      body: boatsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppTheme.deepNavy)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error cargando barcos:\n$error',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        data: (boats) {
          if (boats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay barcos registrados para mostrar en el calendario.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final selectedBoatId = _selectedBoatId ?? boats.first.id;
          final selectedBoat = boats.firstWhere(
            (boat) => boat.id == selectedBoatId,
            orElse: () => boats.first,
          );

          _selectedBoatId ??= selectedBoat.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Selecciona un barco',
                style: textTheme.titleMedium?.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedBoat.id,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.deepNavy.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.oceanBlue,
                      width: 1.8,
                    ),
                  ),
                ),
                items: boats.map((boat) {
                  return DropdownMenuItem<String>(
                    value: boat.id,
                    child: Text(boat.name),
                  );
                }).toList(),
                onChanged: _changeSelectedBoat,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.deepNavy.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedBoat.name,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona fechas para consultar o preparar bloqueos de disponibilidad.',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      locale: 'es_ES',
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      rangeSelectionMode: RangeSelectionMode.toggledOn,
                      rangeStartDay: _rangeStart,
                      rangeEndDay: _rangeEnd,
                      onRangeSelected: (start, end, focusedDay) {
                        setState(() {
                          _rangeStart = start;
                          _rangeEnd = end;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: textTheme.titleLarge!.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.w800,
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
                        weekdayStyle: textTheme.bodySmall!.copyWith(
                          color: AppTheme.deepNavy,
                          fontWeight: FontWeight.bold,
                        ),
                        weekendStyle: textTheme.bodySmall!.copyWith(
                          color: AppTheme.oceanBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppTheme.oceanBlue.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppTheme.deepNavy,
                        ),
                        rangeStartDecoration: const BoxDecoration(
                          color: AppTheme.deepNavy,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: AppTheme.deepNavy,
                          shape: BoxShape.circle,
                        ),
                        rangeHighlightColor: AppTheme.oceanBlue.withValues(
                          alpha: 0.18,
                        ),
                        defaultTextStyle: const TextStyle(
                          color: AppTheme.deepNavy,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: AppTheme.oceanBlue,
                        ),
                        outsideDaysVisible: false,
                      ),
                    ),
                  ],
                ),
              ),
              if (_rangeStart != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.deepNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.deepNavy.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    _rangeEnd == null
                        ? 'Fecha seleccionada: ${_formatDate(_rangeStart!)}'
                        : 'Rango seleccionado: del ${_formatDate(_rangeStart!)} al ${_formatDate(_rangeEnd!)}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _saveSelectedRange,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar selección'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nota: esta pantalla queda preparada para conectarse después con bookings y maintenance_blocks.',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
