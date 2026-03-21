import 'package:flutter/material.dart';


class InputDecorations {

  static InputDecoration defaultInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      // AQUÍ CAMBIAMOS EL COLOR DEL ICONO
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 18, right: 8), // ajusta la posición horizontal
        child: Icon(icon, color: Color.fromARGB(255, 200, 156, 125)),
      ),

      suffixIcon: suffixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(right: 23), // 👈 ajusta esto
            child: suffixIcon,
          )
        : null,

      labelStyle: TextStyle(
        color: Colors.grey, // label cuando NO está seleccionado
      ),

      floatingLabelStyle: TextStyle(
        color: Color.fromARGB(255, 200, 156, 125), // label cuando escribes
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Color.fromARGB(255, 200, 156, 125)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Color.fromARGB(255, 200, 156, 125), width: 2),
      ),
    );
  }



  static ButtonStyle defaultButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 200, 156, 125),
      foregroundColor: Colors.white,
      minimumSize: const Size(500, 50),
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(                 // borde del botón
          color: Colors.white,            // color del borde
          width: 1,                       // grosor del borde
        ),
      ),
    );
  }


  static ButtonStyle deactivatedButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(60, 200, 156, 125),
      foregroundColor: Colors.grey,
      minimumSize: const Size(500, 50),
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30)
      ),
    );
  }


  static ButtonStyle borderButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 23, 23, 23),
      foregroundColor: Colors.white,
      minimumSize: const Size(500, 50),
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(                 // 👈 borde del botón
          color: const Color.fromARGB(255, 85, 83, 83),            // color del borde
          width: 2,                       // grosor del borde
        )
      ),
    );
  }


  static Widget errorMessageBox(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 188, 135, 135),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.red,
            width: 3,
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}