import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/features/auth/register_second.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/home/home_page.dart';
import 'package:http/http.dart' as http;

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
);

class RegisterEmail extends StatefulWidget {
  final int? selectedRole;

  const RegisterEmail({super.key, required this.selectedRole});

  @override
  State<RegisterEmail> createState() => _RegisterEmailState();
}

Future<void> saveUserSessions(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("token", token);
}

class _RegisterEmailState extends State<RegisterEmail> {

  String email= "";
  final emailController = TextEditingController();
  String? errorMessage;
  bool get isFormValid => email.isNotEmpty;

  Future<void> searchEmail() async {
    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/email");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
          "email": email,
          "role": widget.selectedRole
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          errorMessage = null;
        });

        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterPage(selectedRole: widget.selectedRole, email: email)), // Añadir dirección de correo al parámetro
        );
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          errorMessage = data["error"];
        });
      }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) return; // usuario canceló

      final GoogleSignInAuthentication auth = await account.authentication;

      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      final String email = account.email;
      final String? fullName = account.displayName;

      String firstName = "";
      String lastName = "";

      if (fullName != null) {
        final parts = fullName.split(" ");
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";
      }

      await sendGoogleUserToBackend(email, firstName, lastName, idToken);

    } catch (error) {
      print("Error Google Sign-In: $error");
    }
  }

  Future<void> sendGoogleUserToBackend(String email, String firstName, String lastName, String? idToken) async {
    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/google");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "token": idToken,
        "firstname": firstName,
        "lastname": lastName,
        "role": widget.selectedRole,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      await saveUserSessions(data["token"]);

      for(int i=0; i<2; ++i){
        Navigator.pop(context);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      print("Error backend");
    }
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 23, 23, 23)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Asigna un correo', style: TextStyle( fontSize: 33, color: Color.fromARGB(255, 200, 156, 125), fontWeight: FontWeight.bold)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [

                  // TEXTO DE BIENVENIDA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Text('Escriba el correo con el que quiera vincular su cuenta, o prosiga con un correo de Google', 
                      style: TextStyle( fontSize: 20, color: Color.fromARGB(255, 200, 156, 125)),
                      textAlign: TextAlign.justify),
                  ),

                  // ERROR
                  if (errorMessage != null) ...[
                    SizedBox(height: 20),
                    InputDecorations.errorMessageBox(errorMessage!),
                  ],

                  SizedBox(height: 50),

                  // EMAIL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                      controller: emailController,
                      decoration: InputDecorations.defaultInputDecoration(
                        labelText: "Correo electrónico",
                        hintText: "Correo electrónico",
                        icon: Icons.mail_rounded
                      ),
                      onChanged: (value) => setState(() => email = value),
                    ),
                  ),

                  SizedBox(height: 40),

                  // BOTÓN DE CONTINUAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: AbsorbPointer(
                      absorbing: !isFormValid,
                      child: ElevatedButton(
                        onPressed: () { searchEmail();},
                        style: isFormValid
                          ? InputDecorations.defaultButton()
                          : InputDecorations.deactivatedButton(),
                        child: Text("Continuar"),
                      )
                    )
                  ),

                  SizedBox(height: 40),

                  // HR y O
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Color.fromARGB(255, 200, 156, 125),
                            thickness: 2,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "O",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 200, 156, 125),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color.fromARGB(255, 200, 156, 125),
                            thickness: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),
                  
                  // Botón de inicio de sesión con Google.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: ElevatedButton(
                      onPressed: () {signInWithGoogle();},
                      style: InputDecorations.borderButton(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          FaIcon(
                            FontAwesomeIcons.google,
                            color: Color.fromARGB(255, 200, 156, 125),
                          ),

                          SizedBox(width: 13), // 👈 CONTROL TOTAL DEL ESPACIO

                          Text("Registrarse con Google"),
                        ],
                      ),
                    ),
                  ),
                ]
              ),
            ),
          )
          ],
      ),
    );
  }
}