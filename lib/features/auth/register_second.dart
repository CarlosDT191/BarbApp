import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_application_1/features/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/input_decorations.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;


class RegisterPage extends StatefulWidget {
  final int? selectedRole;
  
  const RegisterPage({super.key, required this.selectedRole});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

Future<void> saveUserSession(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("token", token);
}

class _RegisterPageState extends State<RegisterPage> {
  String username= "";
  String password = "";
  String confirmPassword = "";
  String email= "";

  bool get isFormValid => username.isNotEmpty && password.isNotEmpty &&
    confirmPassword.isNotEmpty && email.isNotEmpty && (password == confirmPassword);

  Future<void> registerUser() async {
    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
          "email": email,
          "username": username,
          "password": password,
          "role": widget.selectedRole
        }),
      );

      if (response.statusCode == 200) {

        final Map<String, dynamic> data = jsonDecode(response.body);

        String userToken = data["token"];
        saveUserSession(userToken);

        setState(() {
          errorMessage = null;
        });
        // Quitamos de la pila el register_first y el register_second
        Navigator.pop(context);
        Navigator.pop(context);

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

  String? errorMessage;
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 23, 23, 23)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Datos de la cuenta', style: TextStyle( fontSize: 35, color: Color.fromARGB(255, 200, 156, 125), fontWeight: FontWeight.bold)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [

                  // TEXTO DE BIENVENIDA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text('Especifica todos tus datos correctamente para comenzar en BarbApp', style: TextStyle( fontSize: 18, color: Color.fromARGB(255, 200, 156, 125))),
                  ),
                  
                  // Mensaje de error del BackEnd
                  if (errorMessage != null) ... [
                    SizedBox(height: 20),
                    InputDecorations.errorMessageBox(errorMessage!),
                  ],

                  SizedBox(height: 40),

                  // USERNAME
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                                    controller: usernameController,
                                    decoration: InputDecorations.defaultInputDecoration(
                                    labelText: "Nombre de usuario",
                                    hintText: "Nombre de usuario",
                                    icon: Icons.person
                                  ), 
                                  onChanged: (String value) {
                                    setState(() {
                                      username = value;
                                    });
                                  },
                                  validator: (value){
                                    return value!.isEmpty ? "Please entry username" : null;
                                  },),
                  ),
            
                  SizedBox(height: 50,),

                  // EMAIL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                                    controller: emailController,
                                    decoration: InputDecorations.defaultInputDecoration(
                                    labelText: "Correo electrónico",
                                    hintText: "Correo electrónico",
                                    icon: Icons.mail
                                  ), 
                                  onChanged: (String value) {
                                    setState(() {
                                      email= value;
                                    });
                                  },
                                  validator: (value){
                                    return value!.isEmpty ? "Please entry email" : null;
                                  },),
                  ),
            
                  SizedBox(height: 50,),

                  // PASSWORD
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration:  InputDecorations.defaultInputDecoration(
                          labelText: "Contraseña",
                          hintText: "Contraseña",
                          icon: Icons.password_rounded
                        ),
                        onChanged: (value) {
                          setState(() {
                            password = value;
                          });
                        },
                      ),
                    ),

                  SizedBox(height: 50),

                  // REPETIR PASSWORD
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecorations.defaultInputDecoration(
                          labelText: "Repita la contraseña",
                          hintText: "Repita la contraseña",
                          icon: Icons.password_rounded,
                          suffixIcon: (confirmPassword.isEmpty)
                              ? null
                              : (password == confirmPassword)
                                  ? Icon(Icons.check_circle, color: Colors.green)
                                  : Icon(Icons.cancel, color: Color.fromARGB(255, 224, 122, 95)),
                        ),
                      onChanged: (value) {
                        setState(() {
                          confirmPassword = value;
                        });
                      },
                    ),
                  ),

                SizedBox(height: 50),

                // BOTÓN DE CONTINUAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: AbsorbPointer(
                    absorbing: !isFormValid,
                    child: ElevatedButton(
                      onPressed: () { registerUser();},
                      style: isFormValid
                        ? InputDecorations.defaultButton()
                        : InputDecorations.deactivatedButton(),
                      child: Text("Continuar"),
                    )
                  )
                ),

                SizedBox(height: 40)]

              ),
            ),
          )
          ],
      ),
    );
  }
}