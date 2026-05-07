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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Calendario de flota')),
      body: boatsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.oceanBlue,
            strokeWidth: AppTheme.borderWidthMedium,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Text(
              'Error cargando barcos:\n$error',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(
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
                padding: AppTheme.screenPadding,
                child: Text(
                  'No hay barcos registrados para mostrar en el calendario.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(
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
            padding: AppTheme.listPadding,
            children: [
              Text(
                'Selecciona un barco',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              DropdownButtonFormField<String>(
                initialValue: selectedBoat.id,
                decoration: AppTheme.inputDecoration(
                  labelText: 'Barco',
                  icon: Icons.directions_boat_outlined,
                ),
                dropdownColor: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusInput,
                style: AppTheme.fieldTextStyle.copyWith(
                  color: AppTheme.deepNavy,
                ),
                items: boats.map((boat) {
                  return DropdownMenuItem<String>(
                    value: boat.id,
                    child: Text(
                      boat.name,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _changeSelectedBoat,
              ),
              const SizedBox(height: AppTheme.spacing20),
              Container(
                padding: AppTheme.compactCardPadding,
                decoration: AppTheme.cardDecoration(
                  color: AppTheme.surface,
                  border: Border.all(
                    color: AppTheme.deepNavy.withValues(
                      alpha: AppTheme.alphaSoft,
                    ),
                  ),
                  boxShadow: AppTheme.softShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedBoat.name,
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'Selecciona fechas para consultar o preparar bloqueos de disponibilidad.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                        height: AppTheme.lineHeightRegular,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
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
                      headerStyle: AppTheme.calendarHeaderStyle,
                      daysOfWeekStyle: AppTheme.calendarDaysOfWeekStyle,
                      calendarStyle: AppTheme.calendarStyle,
                    ),
                  ],
                ),
              ),
              if (_rangeStart != null) ...[
                const SizedBox(height: AppTheme.spacing18),
                Container(
                  padding: AppTheme.compactCardPadding,
                  decoration: AppTheme.infoBannerDecoration(AppTheme.deepNavy),
                  child: Text(
                    _rangeEnd == null
                        ? 'Fecha seleccionada: ${_formatDate(_rangeStart!)}'
                        : 'Rango seleccionado: del ${_formatDate(_rangeStart!)} al ${_formatDate(_rangeEnd!)}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing18),
              ElevatedButton.icon(
                onPressed: _saveSelectedRange,
                style: AppTheme.fullWidthPrimaryButtonStyle,
                icon: const Icon(
                  Icons.save_outlined,
                  size: AppTheme.iconSizeLarge,
                ),
                label: Text(
                  'Guardar selección',
                  style: AppTheme.buttonTextStyle.copyWith(
                    color: AppTheme.pearlWhite,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Nota: esta pantalla queda preparada para conectarse después con bookings y maintenance_blocks.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: AppTheme.lineHeightRegular,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
