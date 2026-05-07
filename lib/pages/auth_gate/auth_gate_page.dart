import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/admin_home_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/onboarding/onboarding_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider).checkCurrentSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    if (auth.isLoading && auth.currentUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.oceanBlue,
            strokeWidth: AppTheme.borderWidthMedium,
          ),
        ),
      );
    }

    if (auth.currentUser == null) return const OnboardingPage();

    return switch (auth.currentUser!.role) {
      UserRole.admin => const AdminHomePage(),
      UserRole.customer => const CustomerHomePage(),
    };
  }
}
