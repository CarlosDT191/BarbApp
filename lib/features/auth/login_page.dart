import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/register_type_account.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/config/google_auth_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Aquí declaras GoogleSignIn
  late final GoogleSignIn _googleSignIn = buildGoogleSignIn(
    scopes: const ['email'],
  );
  String username = "";
  String password = "";
  bool isSent = false;
  bool _obscurePassword = true;

  String? errorMessage;

  bool get isFormValid => username.isNotEmpty && password.isNotEmpty;

  Future<void> saveUserSessions(String token, int role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    await prefs.setInt("role", role);
    await prefs.setBool("isLoggedIn", true);
  }

  Future<void> loginUser() async {
    setState(() => isSent = true);

    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String userToken = data["token"];
        int role = data["user"]["role"];
        await saveUserSessions(userToken, role);
        widget.onLogin();

        setState(() {
          errorMessage = null;
        });

        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageOwner()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          errorMessage = data["error"];
          InputDecorations.showTopSnackBarError(context, errorMessage!);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error de conexión";
      });
    }

    setState(() => isSent = false);
  }

  // Función para iniciar sesión con Google
  Future<void> loginWithGoogle() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignorar errores para permitir el inicio de sesion.
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        InputDecorations.showTopSnackBarError(
          context,
          'No se pudo obtener el token de Google.',
        );
        return;
      }

      final fullName = googleUser.displayName?.trim() ?? '';
      final nameParts = fullName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      final firstname = nameParts.isNotEmpty ? nameParts.first : '';
      final lastname = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final apiBaseUrl = getApiBaseUrl();
      final response = await http.post(
        Uri.parse("$apiBaseUrl/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": googleUser.email,
          "token": idToken,
          "firstname": firstname,
          "lastname": lastname,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final userToken = data["token"]?.toString() ?? "";
        final role = (data["user"]?['role'] as num?)?.toInt();

        if (userToken.isEmpty || role == null) {
          InputDecorations.showTopSnackBarError(
            context,
            'Respuesta inválida del servidor.',
          );
          return;
        }

        await saveUserSessions(userToken, role);
        widget.onLogin();

        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageOwner()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final error =
            data["error"]?.toString() ??
            'No se pudo iniciar sesión con Google.';
        InputDecorations.showTopSnackBarError(context, error);
      }
    } catch (e) {
      InputDecorations.showTopSnackBarError(
        context,
        'Error en login con Google: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextSelectionTheme(
      data: const TextSelectionThemeData(
        cursorColor: Color.fromARGB(255, 200, 156, 125),
        selectionHandleColor: Color.fromARGB(255, 200, 156, 125),
        selectionColor: Color.fromARGB(80, 200, 156, 125),
      ),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Inicio de sesión',
                            style: TextStyle(
                              fontSize: 35,
                              color: Color.fromARGB(255, 200, 156, 125),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Form(
                              child: Column(
                                children: [
                                  const SizedBox(height: 50),

                                  // RELLENAR USERNAME
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 35,
                                    ),
                                    child: TextFormField(
                                      decoration:
                                          InputDecorations.defaultInputDecoration(
                                            labelText: "Correo electrónico",
                                            hintText: "Correo electrónico",
                                            icon: Icons.mail_rounded,
                                          ),
                                      cursorColor: const Color.fromARGB(
                                        255,
                                        200,
                                        156,
                                        125,
                                      ),
                                      onChanged: (String value) {
                                        setState(() {
                                          username = value;
                                        });
                                      },
                                      validator: (value) {
                                        return value!.isEmpty
                                            ? "Please entry email"
                                            : null;
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 50),

                                  // RELLENAR CONTRASEÑA
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 35,
                                    ),
                                    child: TextFormField(
                                      obscureText: _obscurePassword,
                                      cursorColor: const Color.fromARGB(
                                        255,
                                        200,
                                        156,
                                        125,
                                      ),
                                      decoration:
                                          InputDecorations.defaultInputDecoration(
                                            labelText: "Contraseña",
                                            hintText: "Contraseña",
                                            icon: Icons.password_rounded,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: Color.fromARGB(
                                                  255,
                                                  200,
                                                  156,
                                                  125,
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                          ),
                                      onChanged: (String value) {
                                        setState(() {
                                          password = value;
                                        });
                                      },
                                      validator: (value) {
                                        return value!.isEmpty
                                            ? "Please entry password"
                                            : null;
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 40),

                                  // Botón de LOGIN
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                    ),
                                    child: InputDecorations.loadingButton(
                                      isSent: isSent,
                                      isEnabled: isFormValid,
                                      text: "Continuar",
                                      onPressed: loginUser,
                                    ),
                                  ),

                                  SizedBox(height: 40),

                                  // HR y O
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Color.fromARGB(
                                              255,
                                              200,
                                              156,
                                              125,
                                            ),
                                            thickness: 2,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            "O",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                255,
                                                200,
                                                156,
                                                125,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Color.fromARGB(
                                              255,
                                              200,
                                              156,
                                              125,
                                            ),
                                            thickness: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 40),

                                  // Botón de inicio de sesión con Google.
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: loginWithGoogle,
                                      style: InputDecorations.borderButton(),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.google,
                                            color: Color.fromARGB(
                                              255,
                                              200,
                                              156,
                                              125,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 13,
                                          ), // 👈 CONTROL TOTAL DEL ESPACIO

                                          Flexible(
                                            child: Text(
                                              "Iniciar sesión con Google",
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 40),

                                  // Botón de Registro
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterRole(),
                                          ),
                                        );
                                      },
                                      style: InputDecorations.borderButton(),
                                      child: Text("Registrarse en BarbApp", textAlign: TextAlign.center),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
