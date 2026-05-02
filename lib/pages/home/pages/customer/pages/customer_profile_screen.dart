import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

// ENUM PARA EL ESTADO DE LA LICENCIA NÁUTICA

enum NauticalLicenseStatus { pending, verified, rejected, none }

NauticalLicenseStatus _statusFromString(String s) {
  switch (s.toLowerCase()) {
    case 'pending':
      return NauticalLicenseStatus.pending;
    case 'verified':
      return NauticalLicenseStatus.verified;
    case 'rejected':
      return NauticalLicenseStatus.rejected;
    default:
      return NauticalLicenseStatus.none;
  }
}

// SCREEN DE PERFIL DEL CLIENTE

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _surnameCtrl;
  late TextEditingController _emailCtrl;

  UserModel? _profile;
  bool _isLoading = true;

  NauticalLicenseStatus _licenseStatus = NauticalLicenseStatus.none;
  String _licenseType = 'none';
  String? _pickedFileName;
  bool _isUploading = false;
  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const _licenseTypes = [
    ('none', 'Sin licencia'),
    ('pnb', 'Patrón de Navegación Básica (PNB)'),
    ('per', 'Patrón de Embarcaciones de Recreo (PER)'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _surnameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authNotifier = ref.read(authNotifierProvider);

    if (authNotifier.currentUser == null) {
      await authNotifier.checkCurrentSession();
    }

    final uid = ref.read(authNotifierProvider).currentUser?.uid;

    if (uid == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('No se pudo obtener el usuario', isError: true);
      }
      return;
    }

    try {
      final repo = ref.read(userRepositoryProvider);
      final profile = await repo.getUser(uid);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.name;
        _surnameCtrl.text = profile.surname;
        _emailCtrl.text = profile.email;
        _licenseStatus = _statusFromString(
          profile.nauticalLicense?.status ?? 'none',
        );
        _licenseType = profile.nauticalLicense?.type ?? 'none';
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error al cargar el perfil: $e', isError: true);
      }
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _pickedFileName = result.files.single.name;
      _isUploading = true;
    });

    try {
      final uid = ref.read(authNotifierProvider).currentUser!.uid;
      final repo = ref.read(userRepositoryProvider);
      final file = XFile(result.files.single.path!);

      final url = await repo.uploadLicenseDocument(uid: uid, file: file);

      await repo.updateNauticalLicense(
        uid: uid,
        type: _licenseType,
        documentUrl: url,
        status: 'pending',
      );

      setState(() {
        _isUploading = false;
        _licenseStatus = NauticalLicenseStatus.pending;
      });
      if (mounted) {
        _showSnack('Documento enviado para verificación', isError: false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        _showSnack('Error al subir el documento: $e', isError: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uid = ref.read(authNotifierProvider).currentUser!.uid;
      final repo = ref.read(userRepositoryProvider);

      await repo.updateProfile(
        uid: uid,
        name: _nameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
      );
      if (mounted) {
        _showSnack('Perfil actualizado correctamente', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('Error al guardar el perfil: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? _OceanRentColors.error
            : _OceanRentColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Build del widget principal con lógica de carga, errores y visualización del perfil

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text('No se pudo cargar el perfil')),
      );
    }

    return Scaffold(
      backgroundColor: _OceanRentColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 32),
                _sectionLabel('Datos Personales'),
                const SizedBox(height: 16),
                _buildPersonalDataCard(),
                const SizedBox(height: 28),
                _sectionLabel('Titulación Náutica'),
                const SizedBox(height: 16),
                _buildNauticalCard(),
                const SizedBox(height: 36),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _OceanRentColors.navy,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: Colors.white,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'OceanRent',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(
            Icons.directions_boat_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    final name = _profile!.name;
    final surname = _profile!.surname;
    final initials = '${name[0]}${surname[0]}'.toUpperCase();

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_OceanRentColors.teal, _OceanRentColors.tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _OceanRentColors.teal.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _OceanRentColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _OceanRentColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: _OceanRentColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$name $surname',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _OceanRentColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _OceanRentColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 12,
                color: _OceanRentColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _OceanRentColors.textSecondary,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildPersonalDataCard() {
    return _Card(
      child: Column(
        children: [
          _buildField(
            controller: _nameCtrl,
            label: 'Nombre',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 20),
          _buildField(
            controller: _surnameCtrl,
            label: 'Apellidos',
            icon: Icons.badge_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 20),
          _buildField(
            controller: _emailCtrl,
            label: 'Correo Electrónico',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo requerido';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: readOnly
            ? _OceanRentColors.textSecondary
            : _OceanRentColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _OceanRentColors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 18, color: _OceanRentColors.textSecondary),
        filled: true,
        fillColor: readOnly
            ? _OceanRentColors.backgroundDim
            : _OceanRentColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OceanRentColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OceanRentColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _OceanRentColors.teal,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OceanRentColors.error),
        ),
      ),
    );
  }

  Widget _buildNauticalCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLicenseStatusBadge(),
          const SizedBox(height: 20),
          _buildLicenseTypeDropdown(),
          const SizedBox(height: 20),
          Divider(color: _OceanRentColors.divider),
          const SizedBox(height: 16),
          _buildDocumentUpload(),
        ],
      ),
    );
  }

  Widget _buildLicenseStatusBadge() {
    final cfg = _licenseStatusConfig(_licenseStatus);
    return Row(
      children: [
        const Text(
          'Estado de verificación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _OceanRentColors.textPrimary,
          ),
        ),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: cfg.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cfg.icon, size: 13, color: cfg.color),
              const SizedBox(width: 5),
              Text(
                cfg.label,
                style: TextStyle(
                  fontSize: 12,
                  color: cfg.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _licenseType,
      decoration: InputDecoration(
        labelText: 'Tipo de titulación',
        labelStyle: const TextStyle(
          color: _OceanRentColors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.anchor_rounded,
          size: 18,
          color: _OceanRentColors.textSecondary,
        ),
        filled: true,
        fillColor: _OceanRentColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OceanRentColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _OceanRentColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _OceanRentColors.teal,
            width: 1.5,
          ),
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: _OceanRentColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: _OceanRentColors.surface,
      borderRadius: BorderRadius.circular(12),
      items: _licenseTypes
          .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _licenseType = val);
      },
    );
  }

  Widget _buildDocumentUpload() {
    final hasFile =
        _pickedFileName != null ||
        (_profile?.nauticalLicense?.documentUrl.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documento acreditativo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _OceanRentColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sube tu titulación en formato PDF, JPG o PNG (máx. 10 MB)',
          style: TextStyle(fontSize: 12, color: _OceanRentColors.textSecondary),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _isUploading ? null : _pickDocument,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: hasFile
                  ? _OceanRentColors.teal.withValues(alpha: 0.04)
                  : _OceanRentColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile
                    ? _OceanRentColors.teal.withValues(alpha: 0.4)
                    : _OceanRentColors.fieldBorder,
                width: 1.5,
              ),
            ),
            child: _isUploading
                ? const Column(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _OceanRentColors.teal,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Subiendo documento...',
                        style: TextStyle(
                          color: _OceanRentColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasFile
                            ? Icons.insert_drive_file_rounded
                            : Icons.upload_file_rounded,
                        color: hasFile
                            ? _OceanRentColors.teal
                            : _OceanRentColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _pickedFileName ??
                              ((_profile
                                          ?.nauticalLicense
                                          ?.documentUrl
                                          .isNotEmpty ??
                                      false)
                                  ? 'Documento subido'
                                  : 'Seleccionar documento'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: hasFile
                                ? _OceanRentColors.teal
                                : _OceanRentColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!hasFile) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _OceanRentColors.teal.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Examinar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _OceanRentColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (_licenseStatus == NauticalLicenseStatus.rejected) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            color: _OceanRentColors.error,
            icon: Icons.info_outline_rounded,
            text: 'Tu documento fue rechazado. Por favor, sube uno nuevo.',
          ),
        ],
        if (_licenseStatus == NauticalLicenseStatus.pending) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            color: _OceanRentColors.warning,
            icon: Icons.hourglass_top_rounded,
            text: 'Documento en revisión. Te avisaremos cuando sea verificado.',
          ),
        ],
        if (_licenseStatus == NauticalLicenseStatus.verified) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            color: _OceanRentColors.success,
            icon: Icons.verified_rounded,
            text: 'Tu titulación náutica ha sido verificada correctamente.',
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _OceanRentColors.teal,
          disabledBackgroundColor: _OceanRentColors.teal.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Guardar cambios',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

//  CONFIGURACIÓN DE ESTADOS DE LICENCIA NÁUTICAS

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

_StatusConfig _licenseStatusConfig(NauticalLicenseStatus status) {
  switch (status) {
    case NauticalLicenseStatus.verified:
      return const _StatusConfig(
        color: _OceanRentColors.success,
        icon: Icons.check_circle_rounded,
        label: 'Verificado',
      );
    case NauticalLicenseStatus.pending:
      return const _StatusConfig(
        color: _OceanRentColors.warning,
        icon: Icons.hourglass_top_rounded,
        label: 'Pendiente',
      );
    case NauticalLicenseStatus.rejected:
      return const _StatusConfig(
        color: _OceanRentColors.error,
        icon: Icons.cancel_rounded,
        label: 'Rechazado',
      );
    case NauticalLicenseStatus.none:
      return const _StatusConfig(
        color: _OceanRentColors.textSecondary,
        icon: Icons.remove_circle_outline_rounded,
        label: 'Sin verificar',
      );
  }
}

// COLORES PERSONALIZADOS DE LA APP EN UN SOLO LUGAR

class _OceanRentColors {
  static const Color navy = Color(0xFF1A2B4A); // AppBar del login
  static const Color teal = Color(0xFF3DBFA8); // Botón "Entrar" del login
  static const Color tealDark = Color(0xFF2A9D8C);
  static const Color background = Color(0xFFF2F2F2); // Fondo gris del login
  static const Color backgroundDim = Color(0xFFE8E8E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color fieldBorder = Color(
    0xFF1A2B4A,
  ); // Borde azul oscuro del login
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF7B8194);
  static const Color divider = Color(0xFFE4E7EF);
  static const Color success = Color(0xFF00C07F);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

// WIDGETS REUTILIZABLES

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _OceanRentColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
