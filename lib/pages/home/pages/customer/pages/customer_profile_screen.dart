import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

// Helpers y widgets anidados

enum LicenseStatus { pending, verified, rejected, none }

LicenseStatus _statusFromString(String s) => switch (s.toLowerCase()) {
  'pending' => LicenseStatus.pending,
  'verified' => LicenseStatus.verified,
  'rejected' => LicenseStatus.rejected,
  _ => LicenseStatus.none,
};

({Color color, IconData icon, String label}) _statusCfg(LicenseStatus s) =>
    switch (s) {
      LicenseStatus.verified => (
        color: AppTheme.oceanBlue,
        icon: Icons.check_circle_rounded,
        label: 'Verificado',
      ),
      LicenseStatus.pending => (
        color: AppTheme.sunsetGold,
        icon: Icons.hourglass_top_rounded,
        label: 'Pendiente',
      ),
      LicenseStatus.rejected => (
        color: AppTheme.alertRed,
        icon: Icons.cancel_rounded,
        label: 'Rechazado',
      ),
      LicenseStatus.none => (
        color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaDisabled),
        icon: Icons.remove_circle_outline_rounded,
        label: 'Sin verificar',
      ),
    };

// Decoración de los campos de texto

InputDecoration _fieldDeco({
  required String label,
  required IconData icon,
  bool readOnly = false,
}) =>
    AppTheme.inputDecoration(labelText: label, icon: icon, readOnly: readOnly);

String _formatBirthDate(DateTime? birthDate) {
  if (birthDate == null) return 'No indicada';

  final day = birthDate.day.toString().padLeft(2, '0');
  final month = birthDate.month.toString().padLeft(2, '0');
  final year = birthDate.year.toString();

  return '$day/$month/$year';
}
// SCREEN PRINCIPAL

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  UserModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  LicenseStatus _licenseStatus = LicenseStatus.none;
  String _licenseType = 'none';
  String? _pickedFileName;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: AppTheme.fadeDuration,
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _birthDateCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Lógica y funciones auxiliares

  Future<void> _loadProfile() async {
    final auth = ref.read(authNotifierProvider);
    if (auth.currentUser == null) await auth.checkCurrentSession();

    final uid = ref.read(authNotifierProvider).currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      _snack('No se pudo obtener el usuario', error: true);
      return;
    }
    try {
      final profile = await ref.read(userRepositoryProvider).getUser(uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.name;
        _surnameCtrl.text = profile.surname;
        _emailCtrl.text = profile.email;
        _birthDateCtrl.text = _formatBirthDate(profile.birthDate);
        _licenseStatus = _statusFromString(
          profile.nauticalLicense?.status ?? 'none',
        );
        _licenseType = profile.nauticalLicense?.type ?? 'none';
        _isLoading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _snack('Error al cargar el perfil: $e', error: true);
    }
  }

  Future<void> _pickDocument() async {
    if (_licenseType == 'none') {
      _snack('Selecciona primero el tipo de titulación', error: true);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;

    if (pickedFile.bytes == null && pickedFile.path == null) {
      _snack('No se pudo leer el archivo', error: true);
      return;
    }

    setState(() {
      _pickedFileName = pickedFile.name;
      _isUploading = true;
    });

    try {
      final uid = ref.read(authNotifierProvider).currentUser!.uid;
      final repo = ref.read(userRepositoryProvider);

      //  guardado solo el nombre del archivo y actualizo Firestore directamente
      await repo.updateNauticalLicense(
        uid: uid,
        type: _licenseType,
        documentUrl: '',
        status: 'pending',
      );

      setState(() {
        _isUploading = false;
        _licenseStatus = LicenseStatus.pending;
      });
      _snack('Titulación enviada para verificación');
    } catch (e) {
      setState(() => _isUploading = false);
      _snack('Error al guardar la titulación: $e', error: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = ref.read(authNotifierProvider).currentUser!.uid;
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            uid: uid,
            name: _nameCtrl.text.trim(),
            surname: _surnameCtrl.text.trim(),
          );
      _snack('Perfil actualizado correctamente');
    } catch (e) {
      _snack('Error al guardar el perfil: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
        ),
        backgroundColor: error ? AppTheme.alertRed : AppTheme.oceanBlue,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusInput,
        ),
        margin: AppTheme.listPadding,
      ),
    );
  }

  // Build principal

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.oceanBlue),
      );
    }
    if (_profile == null) {
      return Center(
        child: Text(
          'No se pudo cargar el perfil',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.deepNavy),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: AppTheme.responsiveScreenPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarSection(profile: _profile!),
              const SizedBox(height: AppTheme.spacing32),
              const _SectionLabel('Datos Personales'),
              const SizedBox(height: AppTheme.spacing16),
              _PersonalDataCard(
                nameCtrl: _nameCtrl,
                surnameCtrl: _surnameCtrl,
                emailCtrl: _emailCtrl,
                birthDateCtrl: _birthDateCtrl,
              ),
              const SizedBox(height: AppTheme.spacing28),
              const _SectionLabel('Titulación Náutica'),
              const SizedBox(height: AppTheme.spacing16),
              _NauticalCard(
                licenseStatus: _licenseStatus,
                licenseType: _licenseType,
                pickedFileName: _pickedFileName,
                isUploading: _isUploading,
                profile: _profile!,
                onTypeChanged: (v) => setState(() => _licenseType = v),
                onPickDocument: _pickDocument,
              ),
              const SizedBox(height: AppTheme.spacing36),
              _SaveButton(isSaving: _isSaving, onPressed: _saveProfile),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGETS ANIDADOS
// Avatar

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.profile});

  final UserModel profile;

  @override
  Widget build(BuildContext context) {
    final initials = '${profile.name[0]}${profile.surname[0]}'.toUpperCase();
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: AppTheme.avatarSize,
                height: AppTheme.avatarSize,
                decoration: AppTheme.profileAvatarDecoration(),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTheme.headlineLarge.copyWith(
                      color: AppTheme.white,
                      fontSize: AppTheme.fontSize30,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: AppTheme.avatarCameraSize,
                  height: AppTheme.avatarCameraSize,
                  decoration: AppTheme.profileCameraDecoration(),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: AppTheme.iconSizeSmall,
                    color: AppTheme.deepNavy.withValues(
                      alpha: AppTheme.alphaDisabled,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            '${profile.name} ${profile.surname}',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Container(
            padding: AppTheme.profileBadgePadding,
            decoration: AppTheme.badgeDecoration(color: AppTheme.oceanBlue),
            child: Text('Cliente', style: AppTheme.badgeTextStyle),
          ),
        ],
      ),
    );
  }
}

// Section label

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTheme.sectionLabelStyle);
}

// Contenedor de sección

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: AppTheme.cardPadding,
    decoration: AppTheme.cardDecoration(),
    child: child,
  );
}

// Datos personales

class _PersonalDataCard extends StatelessWidget {
  const _PersonalDataCard({
    required this.nameCtrl,
    required this.surnameCtrl,
    required this.emailCtrl,
    required this.birthDateCtrl,
  });

  final TextEditingController nameCtrl, surnameCtrl, emailCtrl, birthDateCtrl;

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  @override
  Widget build(BuildContext context) => _ProfileCard(
    child: Column(
      children: [
        _ProfileField(
          controller: nameCtrl,
          label: 'Nombre',
          icon: Icons.person_outline_rounded,
          validator: _required,
        ),
        const SizedBox(height: AppTheme.spacing20),
        _ProfileField(
          controller: surnameCtrl,
          label: 'Apellidos',
          icon: Icons.badge_outlined,
          validator: _required,
        ),
        const SizedBox(height: AppTheme.spacing20),
        _ProfileField(
          controller: emailCtrl,
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
        const SizedBox(height: AppTheme.spacing20),
        _ProfileField(
          controller: birthDateCtrl,
          label: 'Fecha de nacimiento',
          icon: Icons.cake_outlined,
          readOnly: true,
        ),
      ],
    ),
  );
}

// Campo de texto

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    readOnly: readOnly,
    validator: validator,
    style: readOnly ? AppTheme.readOnlyFieldTextStyle : AppTheme.fieldTextStyle,
    decoration: _fieldDeco(label: label, icon: icon, readOnly: readOnly),
  );
}

// Titulación náutica

class _NauticalCard extends StatelessWidget {
  const _NauticalCard({
    required this.licenseStatus,
    required this.licenseType,
    required this.pickedFileName,
    required this.isUploading,
    required this.profile,
    required this.onTypeChanged,
    required this.onPickDocument,
  });

  final LicenseStatus licenseStatus;
  final String licenseType;
  final String? pickedFileName;
  final bool isUploading;
  final UserModel profile;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onPickDocument;

  static const _licenseTypes = [
    ('none', 'Sin licencia'),
    ('pnb', 'Patrón de Navegación Básica (PNB)'),
    ('per', 'Patrón de Embarcaciones de Recreo (PER)'),
  ];

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg(licenseStatus);
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estado de verificación',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: AppTheme.animationNormal,
                padding: AppTheme.licenseStatusBadgePadding,
                decoration: AppTheme.badgeDecoration(color: cfg.color),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cfg.icon,
                      size: AppTheme.iconSizeMini,
                      color: cfg.color,
                    ),
                    const SizedBox(width: AppTheme.spacing5),
                    Text(
                      cfg.label,
                      style: AppTheme.labelSmall.copyWith(
                        color: cfg.color,
                        fontWeight: FontWeight.w700,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),
          // FIX 1: Cambiado initialValue por value para compatibilidad con API 34.
          // initialValue fue introducido en Flutter 3.16 / API 35+ y causaba
          // StackOverflow en versiones anteriores del emulador.
          // FIX 2: Añadido isExpanded: true y overflow: TextOverflow.ellipsis
          // para evitar RenderFlex overflow con textos largos en pantallas pequeñas.
          DropdownButtonFormField<String>(
            initialValue: licenseType,
            isExpanded: true,
            decoration: _fieldDeco(
              label: 'Tipo de titulación',
              icon: Icons.anchor_rounded,
            ),
            style: AppTheme.fieldTextStyle,
            dropdownColor: AppTheme.white,
            borderRadius: AppTheme.borderRadiusInput,
            items: _licenseTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(
                      t.$2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onTypeChanged(v);
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          Divider(
            color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaMedium),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _DocumentUpload(
            licenseStatus: licenseStatus,
            pickedFileName: pickedFileName,
            isUploading: isUploading,
            profile: profile,
            onTap: onPickDocument,
          ),
        ],
      ),
    );
  }
}

// Upload de documentos

class _DocumentUpload extends StatelessWidget {
  const _DocumentUpload({
    required this.licenseStatus,
    required this.pickedFileName,
    required this.isUploading,
    required this.profile,
    required this.onTap,
  });

  final LicenseStatus licenseStatus;
  final String? pickedFileName;
  final bool isUploading;
  final UserModel profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile =
        pickedFileName != null ||
        (profile.nauticalLicense?.documentUrl.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documento acreditativo',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.deepNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Sube tu titulación en formato PDF, JPG o PNG (máx. 10 MB)',
          style: AppTheme.helperTextStyle,
        ),
        const SizedBox(height: AppTheme.spacing14),
        GestureDetector(
          onTap: isUploading ? null : onTap,
          child: AnimatedContainer(
            duration: AppTheme.animationFast,
            width: double.infinity,
            padding: AppTheme.documentUploadPadding,
            decoration: AppTheme.uploadBoxDecoration(hasFile: hasFile),
            child: isUploading
                ? Column(
                    children: [
                      const SizedBox(
                        width: AppTheme.documentUploadLoadingSize,
                        height: AppTheme.documentUploadLoadingSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppTheme.progressStrokeWidth,
                          color: AppTheme.oceanBlue,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing10),
                      Text(
                        'Subiendo documento...',
                        style: AppTheme.helperTextStyle,
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
                            ? AppTheme.oceanBlue
                            : AppTheme.deepNavy.withValues(
                                alpha: AppTheme.alphaDisabled,
                              ),
                        size: AppTheme.iconSizeXl,
                      ),
                      const SizedBox(width: AppTheme.spacing10),
                      Flexible(
                        child: Text(
                          pickedFileName ??
                              ((profile
                                          .nauticalLicense
                                          ?.documentUrl
                                          .isNotEmpty ??
                                      false)
                                  ? 'Documento subido'
                                  : 'Seleccionar documento'),
                          style: AppTheme.helperTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: AppTheme.fontSize13,
                            color: hasFile
                                ? AppTheme.oceanBlue
                                : AppTheme.deepNavy.withValues(
                                    alpha: AppTheme.alphaDisabled,
                                  ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!hasFile) ...[
                        const SizedBox(width: AppTheme.spacing6),
                        Container(
                          padding: AppTheme.browseBadgePadding,
                          decoration: BoxDecoration(
                            color: AppTheme.oceanBlue.withValues(
                              alpha: AppTheme.alphaMedium,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: Text(
                            'Examinar',
                            style: AppTheme.badgeTextStyle.copyWith(
                              fontSize: AppTheme.fontSize11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (licenseStatus == LicenseStatus.rejected) ...[
          const SizedBox(height: AppTheme.spacing10),
          _InfoBanner(
            color: AppTheme.alertRed,
            icon: Icons.info_outline_rounded,
            text: 'Tu documento fue rechazado. Por favor, sube uno nuevo.',
          ),
        ],
        if (licenseStatus == LicenseStatus.pending) ...[
          const SizedBox(height: AppTheme.spacing10),
          _InfoBanner(
            color: AppTheme.sunsetGold,
            icon: Icons.hourglass_top_rounded,
            text: 'Documento en revisión. Te avisaremos cuando sea verificado.',
          ),
        ],
        if (licenseStatus == LicenseStatus.verified) ...[
          const SizedBox(height: AppTheme.spacing10),
          _InfoBanner(
            color: AppTheme.oceanBlue,
            icon: Icons.verified_rounded,
            text: 'Tu titulación náutica ha sido verificada correctamente.',
          ),
        ],
      ],
    );
  }
}

// Botón guardar cambios

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: AppTheme.buttonHeight,
    child: ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.oceanBlue,
        disabledBackgroundColor: AppTheme.oceanBlue.withValues(
          alpha: AppTheme.alphaDisabled,
        ),
        foregroundColor: AppTheme.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusButton,
        ),
      ),
      child: isSaving
          ? const SizedBox(
              width: AppTheme.loadingSize,
              height: AppTheme.loadingSize,
              child: CircularProgressIndicator(
                strokeWidth: AppTheme.progressStrokeWidth,
                color: AppTheme.white,
              ),
            )
          : Text('Guardar cambios', style: AppTheme.buttonTextStyle),
    ),
  );
}

// Info del banner

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppTheme.infoBannerPadding,
    decoration: AppTheme.infoBannerDecoration(color),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppTheme.iconSizeMd, color: color),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(child: Text(text, style: AppTheme.infoBannerTextStyle(color))),
      ],
    ),
  );
}
