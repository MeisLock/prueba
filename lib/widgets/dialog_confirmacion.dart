import 'package:flutter/material.dart';

Future<void> mostrarDialogoConfirmacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required VoidCallback onAceptar,
  String textoCancelar = 'Cancelar',
  String textoAceptar = 'Aceptar',
}) async {
  final eleccion = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(textoCancelar),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(textoAceptar),
        ),
      ],
    ),
  );

  if (eleccion == true) {
    onAceptar();
  }
}