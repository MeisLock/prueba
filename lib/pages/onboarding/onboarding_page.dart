import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/login/login_page.dart';
import 'package:ocean_rent/pages/login/pages/register_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _goToExploreBoats(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CustomerHomePage(isGuest: true)),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goToRegister(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  // Para esta demo, ambos botones llevan a la misma página de login, pero en una app real podrían llevar a flujos diferentes
  // El botón "Explorar Barcos" podría llevar a una versión limitada de la app sin necesidad de iniciar sesión, mientras que "Ya tengo una cuenta" llevaría al login tradicional
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.deepNavy,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.deepNavy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.deepNavy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 22),

                const _OnboardingIndicator(),

                const SizedBox(height: 34),

                const _BoatIllustration(),

                const SizedBox(height: 28),

                Text(
                  'El mar te espera',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppTheme.pearlWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Alquila tu barco perfecto\nahora mismo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppTheme.pearlWhite.withValues(alpha: 0.72),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: 0.2,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: () => _goToExploreBoats(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.oceanBlue,
                      foregroundColor: AppTheme.pearlWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Explorar Barcos',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: () => _goToLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pearlWhite,
                      foregroundColor: AppTheme.deepNavy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Ya tengo una cuenta',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => _goToRegister(context),
                  child: Text(
                    'Registrarme',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.pearlWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  const _OnboardingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.oceanBlue,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 8),
        const _IndicatorDot(),
        const SizedBox(width: 8),
        const _IndicatorDot(),
      ],
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: AppTheme.pearlWhite.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BoatIllustration extends StatelessWidget {
  const _BoatIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 140,
      child: CustomPaint(painter: _BoatIllustrationPainter()),
    );
  }
}

class _BoatIllustrationPainter extends CustomPainter {
  static const Color _boatPurple = Color(0xFF514964);
  static const Color _boatDark = Color(0xFF28334F);
  static const Color _windowBlue = Color(0xFF1D6F9F);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pearlPaint = Paint()
      ..color = AppTheme.pearlWhite
      ..style = PaintingStyle.fill;

    final Paint oceanPaint = Paint()
      ..color = AppTheme.oceanBlue
      ..style = PaintingStyle.fill;

    final Paint boatPaint = Paint()
      ..color = _boatPurple
      ..style = PaintingStyle.fill;

    final Paint boatDarkPaint = Paint()
      ..color = _boatDark
      ..style = PaintingStyle.fill;

    final Paint wavePaint = Paint()
      ..color = _windowBlue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // Sol / luna
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.10, w * 0.32, h * 0.36),
      pearlPaint,
    );

    // Parte superior del barco
    final Path cabin = Path()
      ..moveTo(w * 0.46, h * 0.44)
      ..quadraticBezierTo(w * 0.52, h * 0.34, w * 0.66, h * 0.34)
      ..lineTo(w * 0.78, h * 0.34)
      ..quadraticBezierTo(w * 0.84, h * 0.34, w * 0.86, h * 0.40)
      ..lineTo(w * 0.59, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * 0.40, w * 0.46, h * 0.44)
      ..close();

    canvas.drawPath(cabin, boatPaint);

    // Ventanas superiores
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.61, h * 0.39, w * 0.20, h * 0.035),
        const Radius.circular(8),
      ),
      boatDarkPaint,
    );

    // Mástil
    canvas.drawRect(
      Rect.fromLTWH(w * 0.54, h * 0.10, w * 0.018, h * 0.26),
      oceanPaint,
    );

    // Bandera
    final Path flag = Path()
      ..moveTo(w * 0.56, h * 0.10)
      ..lineTo(w * 0.72, h * 0.12)
      ..quadraticBezierTo(w * 0.68, h * 0.15, w * 0.72, h * 0.17)
      ..lineTo(w * 0.56, h * 0.17)
      ..close();

    canvas.drawPath(flag, oceanPaint);

    // Cuerpo principal del barco
    final Path hull = Path()
      ..moveTo(w * 0.10, h * 0.60)
      ..lineTo(w * 0.92, h * 0.60)
      ..quadraticBezierTo(w * 0.86, h * 0.88, w * 0.62, h * 0.88)
      ..lineTo(w * 0.04, h * 0.88)
      ..lineTo(w * 0.15, h * 0.74)
      ..quadraticBezierTo(w * 0.25, h * 0.72, w * 0.32, h * 0.70)
      ..lineTo(w * 0.26, h * 0.68)
      ..quadraticBezierTo(w * 0.36, h * 0.60, w * 0.46, h * 0.60)
      ..close();

    canvas.drawPath(hull, boatPaint);

    // Cubierta
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.51, w * 0.32, h * 0.05),
        const Radius.circular(10),
      ),
      boatDarkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.52, h * 0.61, w * 0.34, h * 0.05),
        const Radius.circular(10),
      ),
      boatDarkPaint,
    );

    // Ventanas inferiores
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.70, w * 0.44, h * 0.06),
        const Radius.circular(10),
      ),
      boatDarkPaint,
    );

    for (int i = 0; i < 7; i++) {
      final double left = w * (0.42 + i * 0.055);
      canvas.drawRect(
        Rect.fromLTWH(left, h * 0.715, w * 0.027, h * 0.035),
        Paint()..color = _windowBlue.withValues(alpha: 0.55),
      );
    }

    // Olas
    canvas.drawLine(
      Offset(w * 0.08, h * 0.93),
      Offset(w * 0.42, h * 0.93),
      wavePaint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.93),
      Offset(w * 0.92, h * 0.93),
      wavePaint,
    );

    canvas.drawLine(
      Offset(w * 0.08, h * 0.98),
      Offset(w * 0.20, h * 0.98),
      wavePaint,
    );
    canvas.drawLine(
      Offset(w * 0.28, h * 0.98),
      Offset(w * 0.58, h * 0.98),
      wavePaint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.98),
      Offset(w * 0.92, h * 0.98),
      wavePaint,
    );

    canvas.drawLine(
      Offset(w * 0.18, h * 1.03),
      Offset(w * 0.34, h * 1.03),
      wavePaint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 1.03),
      Offset(w * 0.64, h * 1.03),
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
