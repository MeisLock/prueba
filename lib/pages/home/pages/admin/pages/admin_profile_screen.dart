import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

// ─────────────────────────────────────────────
//  SCREEN DE PERFIL DEL ADMINISTRADOR
// ─────────────────────────────────────────────

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  /// Navega a esta pantalla desde cualquier contexto.
  static void navigate(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
  }

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _surnameCtrl;
  late TextEditingController _emailCtrl;
  UserModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

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

  // ── Carga del perfil ──────────────────────────────────────────────────────

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

  // ── Guardar cambios ───────────────────────────────────────────────────────

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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Snackbar helper ───────────────────────────────────────────────────────

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

  // ── Build principal ───────────────────────────────────────────────────────

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

  // ── AppBar ────────────────────────────────────────────────────────────────

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

  // ── Avatar + nombre + badge admin ────────────────────────────────────────

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
          // Badge "Administrador" con color navy en lugar del teal del cliente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _OceanRentColors.navy.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _OceanRentColors.navy.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.shield_rounded,
                  size: 12,
                  color: _OceanRentColors.navy,
                ),
                SizedBox(width: 4),
                Text(
                  'administrador',
                  style: TextStyle(
                    fontSize: 12,
                    color: _OceanRentColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Etiqueta de sección ───────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _OceanRentColors.textSecondary,
      letterSpacing: 0.8,
    ),
  );

  // ── Tarjeta de datos personales ───────────────────────────────────────────

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

  // ── Campo de texto reutilizable ───────────────────────────────────────────

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

  // ── Botón guardar ─────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  COLORES (mismos que en CustomerProfileScreen)
// ─────────────────────────────────────────────

class _OceanRentColors {
  static const Color navy = Color(0xFF1A2B4A);
  static const Color teal = Color(0xFF3DBFA8);
  static const Color tealDark = Color(0xFF2A9D8C);
  static const Color background = Color(0xFFF2F2F2);
  static const Color backgroundDim = Color(0xFFE8E8E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color fieldBorder = Color(0xFF1A2B4A);
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF7B8194);
  static const Color divider = Color(0xFFE4E7EF);
  static const Color success = Color(0xFF00C07F);
  static const Color error = Color(0xFFEF4444);
}

// ─────────────────────────────────────────────
//  WIDGETS REUTILIZABLES
// ─────────────────────────────────────────────

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
