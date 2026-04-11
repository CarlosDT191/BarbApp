import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:another_flushbar/flushbar.dart';
import '../../services/user_service.dart';
import 'package:http/http.dart' as http;


class ChangeProfilePage extends StatefulWidget {  
  const ChangeProfilePage({super.key});

  @override
  State<ChangeProfilePage> createState() => _ChangeProfilePageState();
}

Future<void> saveUserSessions(String token, int role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("token", token);
  await prefs.setInt("role", role);
}

class _ChangeProfilePageState extends State<ChangeProfilePage> {
  String? firstname;
  String? lastname;
  bool isLoading = true;
  bool isSent = false;
  late final TextEditingController firstnameController;
  late final TextEditingController lastnameController;

  bool get isFormValid => firstname?.isNotEmpty == true && lastname?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    firstnameController = TextEditingController();
    lastnameController = TextEditingController();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final userData = await UserService.getCurrentUser();
      setState(() {
        firstname = userData['firstname'] ?? "Usuario";
        lastname = userData['lastname'] ?? "";
        firstnameController.text = firstname!;
        lastnameController.text = lastname!;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      InputDecorations.showTopSnackBarError(context, "Error al cargar datos: $e");
    }
  }

  Future<void> updateProfile() async {
    setState(() => isSent = true);

    try {
      final response = await UserService.updateProfile(
        firstname: firstnameController.text,
        lastname: lastnameController.text,
      );

      final message = response["message"] ?? "Perfil actualizado";

      if (!mounted) return;

      Navigator.pop(context, true);
      InputDecorations.showTopSnackBarSuccess(context, message);

    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, e.toString().replaceAll("Exception: ", ""));
      }
      setState(() => isSent = false);
    }
  }


  String? errorMessage;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    
    // PANTALLA DE CARGA
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 23, 23, 23)),
        backgroundColor: Color.fromARGB(255, 23, 23, 23),
        body: const Center(
          child: CircularProgressIndicator(color: Color.fromARGB(255, 200, 156, 125)),
        ),
      );
    }

    // PANTALLA PRINCIPAL
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 23, 23, 23)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // TÍTULO
                    Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 35,
                        color: Color.fromARGB(255, 200, 156, 125),
                        fontWeight: FontWeight.bold
                      )
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Form(
                        child: Column(
                          children: [

                            // SUBTÍTULO
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                'Modifica el nombre y los apellidos asociados a tu cuenta',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 200, 156, 125)
                                )
                              ),
                            ),

                            SizedBox(height: 50),

                            // CAMBIAR NOMBRE
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: firstnameController,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Nombre",
                                  hintText: "Escribe tu nombre",
                                  icon: Icons.person
                                ),
                                onChanged: (value) => setState(() => firstname = value),
                              ),
                            ),

                            SizedBox(height: 40),

                            // CAMBIAR APELLIDOS
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: lastnameController,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Apellidos",
                                  hintText: "Escribe tus apellidos",
                                  icon: Icons.person
                                ),
                                onChanged: (value) => setState(() => lastname = value),
                              ),
                            ),

                            SizedBox(height: 60),

                            // BOTÓN DE ENVÍO
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50),
                              child: InputDecorations.loadingButton(
                                  isSent: isSent,
                                  isEnabled: isFormValid,
                                  text: "Confirmar cambios",
                                  onPressed: updateProfile,
                                ),
                            ),

                            SizedBox(height: 40),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}