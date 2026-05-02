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
  File? _selectedImage;
  bool _isPickingImage = false;
  String imageUrlCloud = "noURL";

  bool get isEditing => widget.boat != null;

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
    }

    _imageUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
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
      debugPrint("Error seleccionando imagen: $e");
    }

    setState(() => _isPickingImage = false);
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
        );
      } else {
        await BoatService.instance.createBoat(
          name: name,
          category: category,
          capacity: capacity,
          pricePerDay: price,
          description: description,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Barco actualizado correctamente'
                : 'Barco creado correctamente',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando barco: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.deepNavy.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 52,
          color: AppTheme.deepNavy.withValues(alpha: 0.55),
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
          'Foto del barco (URL)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            color: AppTheme.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.deepNavy.withValues(alpha: 0.15),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : (url.isNotEmpty
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder()),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPickingImage ? null : _pickImage,
            child: _isPickingImage
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Seleccionar imagen"),
          ),
        ),
        const SizedBox(height: 6),

        Text(
          'Selecciona una imagen. Se subirá cuando guardes el formulario.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        if (_selectedImage != null)
          TextButton(
            onPressed: () => setState(() => _selectedImage = null),
            child: const Text("Eliminar imagen"),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.deepNavy.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.oceanBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar barco' : 'Crear barco')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildImageSection(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nombre'),
                validator: _validateRequired,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBoatType,
                decoration: _inputDecoration('Tipo de barco'),
                items: _boatTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(_boatTypeLabel(type)),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Capacidad'),
                validator: _validateCapacity,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration('Precio por día (€)'),
                validator: _validatePrice,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Descripción'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save, // ← Así debe estar
                  child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                ),
              ),
              const SizedBox(height: 12),
              if (!isEditing)
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AdminHomePage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepNavy,
                      side: BorderSide(
                        color: AppTheme.deepNavy.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text('Volver al panel'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
