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


class ChangePasswordPage extends StatefulWidget {  
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

/// Guarda el token JWT y el rol del usuario en [SharedPreferences].
///
/// [token] es el token JWT obtenido del backend (`String`).
/// [role] es el rol del usuario: 0=cliente, 1=propietario, 2=admin (`int`).
///
/// Permite mantener la sesión activa entre ejecuciones de la aplicación.
Future<void> saveUserSessions(String token, int role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("token", token);
  await prefs.setInt("role", role);
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  String? currentPassword;
  String? newPassword;
  String? confirmPassword;
  String? actual_password;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  bool isLoading = true;
  bool isSent = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool get isFormValid => currentPassword?.isNotEmpty == true && newPassword?.isNotEmpty == true && confirmPassword?.isNotEmpty == true && (newPassword == confirmPassword);

  /// Muestra un diálogo para cambiar la contraseña del usuario.
  ///
  /// Permite al usuario ingresar la contraseña actual, una nueva contraseña
  /// y la confirmación. Valida y procesa el cambio al presionar el botón.
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Contraseña"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña Actual"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Nueva Contraseña"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmar Nueva Contraseña"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await UserService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmPasswordController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contraseña actualizada exitosamente")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            child: const Text("Cambiar"),
          ),
        ],
      ),
    );
  }

  /// Carga los datos del usuario desde el servidor.
  ///
  /// Recupera información del usuario actual usando [UserService.getCurrentUser]
  /// para validaciones posteriores (ej: verificar si la cuenta es de Google).
  Future<void> loadUserData() async {
    try {
      final userData = await UserService.getCurrentUser();
      setState(() {
        actual_password = userData['password'] ?? "";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }
  }

  /// Procesa el cambio de contraseña del usuario.
  ///
  /// Valida que la contraseña actual sea correcta mediante [UserService.changePassword],
  /// envía la solicitud al backend y cierra la página si el cambio es exitoso.
  Future<void> handleChangePassword() async {
    setState(() => isSent = true);
    try {
      final response = await UserService.changePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      final message = response["message"] ?? "Contraseña actualizada exitosamente";

      if (mounted) {
        Navigator.pop(context, true);
        InputDecorations.showTopSnackBarSuccess(context, message);
      }
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, e.toString().replaceAll("Exception: ", ""));
      }
      setState(() => isSent = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

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

                    Text(
                      'Cambiar contraseña',
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
                                'Modifica la contraseña de tu cuenta',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 200, 156, 125)
                                )
                              ),
                            ),

                            SizedBox(height: 50),

                            // CONTRASEÑA ACTUAL
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: currentPasswordController,
                                obscureText: _obscureCurrentPassword,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Contraseña actual",
                                  hintText: "Escribe tu contraseña actual",
                                  icon: Icons.password_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureCurrentPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Color.fromARGB(255, 200, 156, 125),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureCurrentPassword = !_obscureCurrentPassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) => setState(() => currentPassword = value),
                              ),
                            ),

                            SizedBox(height: 40),

                            // NUEVA CONTRASEÑA
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: newPasswordController,
                                obscureText: _obscureNewPassword,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Nueva contraseña",
                                  hintText: "Escribe tu nueva contraseña",
                                  icon: Icons.password_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Color.fromARGB(255, 200, 156, 125),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureNewPassword = !_obscureNewPassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) => setState(() => newPassword = value),
                              ),
                            ),

                            SizedBox(height: 40),

                            // CONFIRM PASSWORD
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Repita la nueva contraseña",
                                  hintText: "Repita la nueva contraseña",
                                  icon: Icons.password_rounded,
                                  suffixIcon: confirmPassword?.isEmpty == true
                                    ? null
                                    : (newPassword == confirmPassword)
                                      ? Icon(Icons.check_circle, color: Colors.green)
                                      : Icon(Icons.cancel, color: Colors.red),
                                ),
                                onChanged: (value) => setState(() => confirmPassword = value),
                              ),
                            ),
                            
                            SizedBox(height: 60),

                            // BOTÓN
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50),
                              child: InputDecorations.loadingButton(
                                  isSent: isSent,
                                  isEnabled: isFormValid,
                                  text: "Confirmar cambios",
                                  onPressed: handleChangePassword,
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