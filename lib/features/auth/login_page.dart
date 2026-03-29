import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/register_second.dart';
import 'package:flutter_application_1/features/auth/register_first.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/home/home_page.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // Aquí declaras GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String username= "";
  String password= "";

  String? errorMessage;

  bool get isFormValid => username.isNotEmpty && password.isNotEmpty;

  Future<void> loginUser() async {
    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
          "email": username,
          "password": password
        }),
      );

      if (response.statusCode == 200) {

        final Map<String, dynamic> data = jsonDecode(response.body);

        String userToken = data["token"];
        saveUserSession(userToken);

        setState(() {
          errorMessage = null;
        });
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          errorMessage = data["error"];
        });
      }
  }

  // Función para iniciar sesión con Google
  Future<void> loginWithGoogle() async {
    try {
      // Inicia sesión con Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // El usuario canceló la operación
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crea credenciales de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión en Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Usuario logueado
        print('Usuario logueado: ${userCredential.user?.displayName}');
    } catch (e) {
      print('Error en login con Google: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Inicio de sesión', style: TextStyle( fontSize: 35, color: Color.fromARGB(255, 200, 156, 125), fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [

                  // Mensaje de error del BackEnd
                  if (errorMessage != null)
                    InputDecorations.errorMessageBox(errorMessage!),

                  SizedBox(height: 50),
    
                  // RELLENAR USERNAME
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(decoration: InputDecorations.defaultInputDecoration(
                                    labelText: "Correo electrónico",
                                    hintText: "Correo electrónico",
                                    icon: Icons.mail_rounded
                                  ), 
                                  onChanged: (String value) {
                                    setState(() {
                                      username = value;
                                    });
                                  },
                                  validator: (value){
                                    return value!.isEmpty ? "Please entry email" : null;
                                  },),
                  ),
            
                  SizedBox(height: 50,),
            
                  // RELLENAR CONTRASEÑA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(obscureText: true, decoration: InputDecorations.defaultInputDecoration(
                                    labelText: "Contraseña",
                                    hintText: "Contraseña",
                                    icon: Icons.password_rounded
                                  ), 
                                  onChanged: (String value) {
                                    setState(() {
                                      password = value;
                                    });
                                  },
                                  validator: (value){
                                    return value!.isEmpty ? "Please entry password" : null;
                                  },),
                  ),

                SizedBox(height: 40),
                
                // Botón de LOGIN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: AbsorbPointer(
                    absorbing: !isFormValid,
                    child: ElevatedButton(
                      onPressed: () { loginUser();},
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
                    onPressed: loginWithGoogle,
                    style: InputDecorations.borderButton(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        FaIcon(
                          FontAwesomeIcons.google,
                          color: Color.fromARGB(255, 200, 156, 125),
                        ),

                        SizedBox(width: 13), // 👈 CONTROL TOTAL DEL ESPACIO

                        Text("Iniciar sesión con Google"),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Botón de Registro
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterRole()),
                      );},
                    style: InputDecorations.borderButton(),
                    child: Text("Registarse en BarbApp"),
                  )
                ),


                ],

              ),
            ),
          )
          ],
      ),
    );
  }
}