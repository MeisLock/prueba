import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/admin_home_page.dart';
import 'package:ocean_rent/services/boat/boat_service.dart';

import '../../../../../services/image/image_compress.dart';
import '../../../../../services/image/image_picker_service.dart';
import '../../../../../services/image/image_saver_service.dart';

class BoatFormPage extends StatefulWidget {
  final BoatModel? boat;

  const BoatFormPage({super.key, this.boat});

  @override
  State<BoatFormPage> createState() => _BoatFormPageState();
}

class _BoatFormPageState extends State<BoatFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _portNameController = TextEditingController();

  final List<String> _boatTypes = const [
    'lancha',
    'semirigida',
    'velero',
    'yate',
    'catamaran',
    'jetski',
  ];

  String? _selectedBoatType;
  bool _isSaving = false;
  bool _isPickingImage = false;
  File? _selectedImage;
  String imageUrlCloud = 'noURL';

  bool get isEditing => widget.boat != null;

  @override
  void initState() {
    super.initState();

    final boat = widget.boat;

    if (boat != null) {
      _nameController.text = boat.name;
      _selectedBoatType = _normalizeBoatType(boat.category);
      _capacityController.text = boat.capacity.toString();
      _priceController.text = boat.pricePerDay.toString();
      _descriptionController.text = boat.description;
      _imageUrlController.text = boat.imageUrl;
      _portNameController.text = boat.portName;
    }

    _imageUrlController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _portNameController.dispose();
    super.dispose();
  }

  String? _normalizeBoatType(String? type) {
    if (type == null) return null;

    final normalized = type
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(' ', '');

    switch (normalized) {
      case 'lancha':
        return 'lancha';
      case 'semirigida':
      case 'semirrigida':
        return 'semirigida';
      case 'velero':
        return 'velero';
      case 'yate':
        return 'yate';
      case 'catamaran':
        return 'catamaran';
      case 'jetski':
      case 'jetsky':
        return 'jetski';
      default:
        return null;
    }
  }

  String _boatTypeLabel(String type) {
    switch (type) {
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
        return type;
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);

    try {
      final pickerService = ImagePickerService();
      final images = await pickerService.pickMultipleImages();

      if (images.isEmpty) return;

      final compressed = await compressImage(images.first);

      if (compressed != null) {
        setState(() {
          _selectedImage = compressed;
        });
      }
    } catch (e) {
      debugPrint('Error seleccionando imagen: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _imageUrlController.text.trim();

      if (_selectedImage != null) {
        finalImageUrl = await uploadToCloudinary(_selectedImage!);

        if (finalImageUrl == null || finalImageUrl.isEmpty) {
          throw Exception('No se pudo subir la imagen a Cloudinary');
        }

        imageUrlCloud = finalImageUrl;
      }

      final name = _nameController.text.trim();
      final category = _selectedBoatType?.trim() ?? '';
      final capacity = int.parse(_capacityController.text.trim());
      final price = double.parse(
        _priceController.text.trim().replaceAll(',', '.'),
      );
      final description = _descriptionController.text.trim();
      final portName = _portNameController.text.trim();
      final imageUrl = finalImageUrl.isNotEmpty
          ? finalImageUrl
          : _imageUrlController.text.trim();

      if (isEditing) {
        await BoatService.instance.updateBoat(
          id: widget.boat!.id,
          name: name,
          category: category,
          capacity: capacity,
          pricePerDay: price,
          description: description,
          imageUrl: imageUrl,
          portName: portName,
        );
      } else {
        await BoatService.instance.createBoat(
          name: name,
          category: category,
          capacity: capacity,
          pricePerDay: price,
          description: description,
          imageUrl: imageUrl,
          portName: portName,
        );
      }

      if (!mounted) return;

      _showSnack(
        isEditing
            ? 'Barco actualizado correctamente'
            : 'Barco creado correctamente',
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      _showSnack('Error guardando barco: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
        ),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusInput,
        ),
        margin: AppTheme.listPadding,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }

    return null;
  }

  String? _validateCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }

    final number = int.tryParse(value.trim());

    if (number == null) return 'Introduce un número válido';
    if (number <= 0) return 'La capacidad debe ser mayor que 0';

    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));

    if (parsed == null) return 'Introduce un precio válido';
    if (parsed <= 0) return 'El precio debe ser mayor que 0';

    return null;
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return AppTheme.inputDecoration(labelText: label, icon: icon);
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: AppTheme.imagePickerIconSize,
          color: AppTheme.deepNavy.withValues(
            alpha: AppTheme.alphaTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final url = _imageUrlController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto del barco',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          height: AppTheme.formImagePreviewHeight,
          width: double.infinity,
          decoration: AppTheme.cardDecoration(
            color: AppTheme.surface,
            radius: AppTheme.radiusButton,
            border: Border.all(
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaChip),
            ),
            boxShadow: [],
          ),
          child: ClipRRect(
            borderRadius: AppTheme.borderRadiusButton,
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          width: double.infinity,
          height: AppTheme.compactButtonHeight,
          child: ElevatedButton.icon(
            onPressed: _isPickingImage ? null : _pickImage,
            style: AppTheme.accentButtonStyle,
            icon: _isPickingImage
                ? const SizedBox(
                    width: AppTheme.loadingSize,
                    height: AppTheme.loadingSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppTheme.progressStrokeWidth,
                      color: AppTheme.white,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: AppTheme.iconSizeLarge,
                  ),
            label: Text(
              _isPickingImage ? 'Seleccionando...' : 'Seleccionar imagen',
              style: AppTheme.buttonTextStyle.copyWith(color: AppTheme.white),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing6),
        Text(
          'Selecciona una imagen. Se subirá cuando guardes el formulario.',
          style: AppTheme.helperTextStyle.copyWith(color: AppTheme.textMuted),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: AppTheme.spacing8),
          TextButton.icon(
            onPressed: () => setState(() => _selectedImage = null),
            style: AppTheme.compactTextButtonStyle,
            icon: const Icon(
              Icons.delete_outline,
              size: AppTheme.iconSizeLarge,
              color: AppTheme.alertRed,
            ),
            label: Text(
              'Eliminar imagen',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(isEditing ? 'Editar barco' : 'Crear barco')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppTheme.listPadding,
            children: [
              _buildImageSection(),
              const SizedBox(height: AppTheme.spacing20),
              TextFormField(
                controller: _nameController,
                style: AppTheme.fieldTextStyle,
                decoration: _inputDecoration(
                  'Nombre',
                  icon: Icons.directions_boat_outlined,
                ),
                validator: _validateRequired,
              ),
              const SizedBox(height: AppTheme.spacing12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBoatType,
                decoration: _inputDecoration(
                  'Tipo de barco',
                  icon: Icons.category_outlined,
                ),
                dropdownColor: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusInput,
                style: AppTheme.fieldTextStyle,
                items: _boatTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          _boatTypeLabel(type),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.deepNavy,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBoatType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obligatorio';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                style: AppTheme.fieldTextStyle,
                decoration: _inputDecoration(
                  'Capacidad',
                  icon: Icons.people_outline,
                ),
                validator: _validateCapacity,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _portNameController,
                style: AppTheme.fieldTextStyle,
                decoration: _inputDecoration(
                  'Puerto / ubicación',
                  icon: Icons.location_on_outlined,
                ),
                validator: _validateRequired,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTheme.fieldTextStyle,
                decoration: _inputDecoration(
                  'Precio por día (€)',
                  icon: Icons.euro_outlined,
                ),
                validator: _validatePrice,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: AppTheme.fieldTextStyle,
                decoration: _inputDecoration(
                  'Descripción',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                height: AppTheme.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: AppTheme.fullWidthPrimaryButtonStyle,
                  child: Text(
                    _isSaving ? 'Guardando...' : 'Guardar',
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: AppTheme.pearlWhite,
                    ),
                  ),
                ),
              ),
              if (!isEditing) ...[
                const SizedBox(height: AppTheme.spacing12),
                SizedBox(
                  height: AppTheme.compactButtonHeight,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AdminHomePage(),
                        ),
                      );
                    },
                    style: AppTheme.outlinedButtonStyle,
                    child: Text(
                      'Volver al panel',
                      style: AppTheme.buttonTextStyle.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
