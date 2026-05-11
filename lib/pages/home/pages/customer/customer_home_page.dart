import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/boat_list_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_profile_screen.dart';
import 'package:ocean_rent/pages/onboarding/onboarding_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/widgets/app_navigator.dart';
import 'package:ocean_rent/widgets/dialog_confirmacion.dart';

class CustomerHomePage extends ConsumerStatefulWidget {
  final List<String> initialCategories;

  const CustomerHomePage({super.key, this.initialCategories = const []});

  // Esta página se ha creado para los usuarios regulares que tengan solo el rol de cliente u anónimos
  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider).signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (_) => false,
    );
  }

  void _onDestinationSelected(int index, bool isAnonymous) {
    if (isAnonymous && index != 0) {
      AppNavigator.goToLogin(context);
      return;
    }
    setState(() => selectedIndex = index);
  }

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).currentUser;
    final isAnonymous = user == null;
    final List<Widget> pages = [
      BoatListPage(categoriasIniciales: widget.initialCategories),
      const Center(child: Text('Mapa')),
      // Se tiene que implementar el mapa
      const Center(child: Text('Chat')),
      // Posible implementación de un chat para hablar con el admin del barco
      const Center(child: Text('Reservas')),
      // Se tiene que implementar, aquí se deberían de ver las solitudes de reservas(aceptadas o pendientes)
      isAnonymous
          ? const Center(child: Text('Inicia sesión para ver tu perfil'))
          : const CustomerProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ocean Rent'),
        actions: [
          if (!isAnonymous)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                mostrarDialogoConfirmacion(
                  context,
                  titulo: 'Cerrar Sesión',
                  mensaje: '¿Quieres cerrar sesión?',
                  onAceptar: () {
                    _logout(context, ref);
                  },
                );
              },
            ),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: NavigationBar(
          shadowColor: Colors.black.withValues(alpha: 0.2),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _onDestinationSelected(index, isAnonymous),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
