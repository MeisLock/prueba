import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/pages/login/login_page.dart';
import 'package:ocean_rent/widgets/dialog_confirmacion.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_boat_list_page.dart'; 

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

    //Esta página se ha creado para los ususarios regulares que tengan solo el rol de cliente en la base de datos

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('OceanRent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => mostrarDialogoConfirmacion(
              context, 
              titulo: 'Cerrar Sesión', 
              mensaje: '¿Quieres cerrar sesión?', 
              onAceptar: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage())
                );
              }
            ),
          ),
        ],
      ),
      body: const CustomerBoatListPage(),
    );
  }
}