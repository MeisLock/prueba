import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/pages/home/pages/customer_home_page.dart';
import 'package:ocean_rent/pages/login/login_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/widgets/build_label_text_fields.dart';
import 'package:ocean_rent/widgets/custom_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/$date.year';
  }

  Future<void> _selectBirthDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final initialDate =
        _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthDate = pickedDate;
        _birthDateController.text = _formatDate(pickedDate);
      });
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider).clearError();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones
    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos.')),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de nacimiento.')),
      );
      return;
    }

    if (!email.contains('@')) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Introduce un correo válido.')),
      );
      return;
    }

    if (password.length < 6) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    final success = await ref
        .read(authNotifierProvider)
        .registerWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
          surname: surname,
          birthDate: _selectedBirthDate!,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
        (_) => false,
      );
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo completar el registro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.pearlWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.deepNavy,
        title: const Text('OceanRent'),
        actions: [
          const Icon(Icons.directions_boat_outlined),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: AppTheme.pearlWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Registro',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 28),
                      buildLabelTextFields(context, 'Nombre'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _nameController,
                        hintText: '',
                        obscureText: false,
                      ),
                      const SizedBox(height: 22),
                      buildLabelTextFields(context, 'Apellidos'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _surnameController,
                        hintText: '',
                        obscureText: false,
                      ),
                      const SizedBox(height: 22),
                      buildLabelTextFields(context, 'Fecha de nacimiento'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectBirthDate,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _birthDateController,
                            hintText: 'dd/mm/aaaa',
                            obscureText: false,
                            suffixIcon: IconButton(
                              onPressed: _selectBirthDate,
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                color: AppTheme.deepNavy,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      buildLabelTextFields(context, 'Correo electrónico'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: '',
                        obscureText: false,
                      ),
                      const SizedBox(height: 22),
                      buildLabelTextFields(context, 'Contraseña'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        hintText: '',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.deepNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      buildLabelTextFields(context, 'Confirmar contraseña'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        hintText: '',
                        onSubmitted: (_) => _register(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.deepNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.oceanBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Registrarse',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (_) => false,
                                );
                              },
                        child: Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.oceanBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (authState.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          authState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.alertRed,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
