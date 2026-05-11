import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class FilterDrawer extends StatelessWidget {
  final List<String> selectedCategory;
  final List<String> selectedPorts;
  final RangeValues rangedPrice;
  final RangeValues rangedCapacity;
  final List<String> categories;
  final List<String> ports;
  final VoidCallback onReset;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPortChanged;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<RangeValues> onCapacityChanged;

  const FilterDrawer({
    super.key,
    required this.selectedCategory,
    required this.selectedPorts,
    required this.rangedPrice,
    required this.rangedCapacity,
    required this.categories,
    required this.ports,
    required this.onReset,
    required this.onCategoryChanged,
    required this.onPortChanged,
    required this.onPriceChanged,
    required this.onCapacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                    ),
                    TextButton(
                      onPressed: onReset,
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Categoría',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = selectedCategory.contains(category);
                    return FilterChip(
                      label: Text(
                        category[0].toUpperCase() + category.substring(1),
                      ),
                      selected: isSelected,
                      onSelected: (_) => onCategoryChanged(category),
                      selectedColor: AppTheme.oceanBlue.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.deepNavy,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.deepNavy
                            : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.deepNavy
                            : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                Text(
                  'Ubicación',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                if (ports.isEmpty)
                  Text(
                    'No hay ubicaciones disponibles',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ports.map((port) {
                      final isSelected = selectedPorts.contains(port);

                      return FilterChip(
                        avatar: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: isSelected
                              ? AppTheme.deepNavy
                              : Colors.grey.shade600,
                        ),
                        label: Text(port),
                        selected: isSelected,
                        onSelected: (_) => onPortChanged(port),
                        selectedColor: AppTheme.oceanBlue.withValues(
                          alpha: 0.2,
                        ),
                        checkmarkColor: AppTheme.deepNavy,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.deepNavy
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.deepNavy
                              : Colors.grey.shade300,
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio por día (€)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepNavy,
                      ),
                    ),
                    Text(
                      '${rangedPrice.start.toInt()}€ - ${rangedPrice.end.toInt()}€',
                      style: TextStyle(color: AppTheme.deepNavy),
                    ),
                  ],
                ),
                RangeSlider(
                  values: rangedPrice,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  activeColor: AppTheme.deepNavy,
                  inactiveColor: AppTheme.deepNavy.withValues(alpha: 0.2),
                  labels: RangeLabels(
                    '${rangedPrice.start.toInt()}€',
                    '${rangedPrice.end.toInt()}€',
                  ),
                  onChanged: onPriceChanged,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacidad',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepNavy,
                      ),
                    ),
                    Text(
                      '${rangedCapacity.start.toInt()} - ${rangedCapacity.end.toInt()} personas',
                      style: TextStyle(color: AppTheme.deepNavy),
                    ),
                  ],
                ),
                RangeSlider(
                  values: rangedCapacity,
                  min: 1,
                  max: 100,
                  divisions: 25,
                  activeColor: AppTheme.deepNavy,
                  inactiveColor: AppTheme.deepNavy.withValues(alpha: 0.2),
                  labels: RangeLabels(
                    '${rangedCapacity.start.toInt()}',
                    '${rangedCapacity.end.toInt()}',
                  ),
                  onChanged: onCapacityChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
