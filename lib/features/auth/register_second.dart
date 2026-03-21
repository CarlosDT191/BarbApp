import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_application_1/features/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;


class RegisterPage extends StatefulWidget {
  final int? selectedRole;
  final String? email;
  
  const RegisterPage({super.key, required this.selectedRole, required this.email});

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

  bool get isFormValid => username.isNotEmpty && password.isNotEmpty &&
    confirmPassword.isNotEmpty && (password == confirmPassword);

  Future<void> registerUser() async {
    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
          "email": widget.email,
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

        // Quitamos de la pila el register_first, el register_email y el register_second
        for(int i=0; i<3; ++i){
          Navigator.pop(context);
        }

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
                      'Datos de la cuenta',
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

                            // TEXTO DE BIENVENIDA
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                'Especifica todos tus datos correctamente para comenzar en BarbApp',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 200, 156, 125)
                                )
                              ),
                            ),

                            // ERROR
                            if (errorMessage != null) ...[
                              SizedBox(height: 20),
                              InputDecorations.errorMessageBox(errorMessage!),
                            ],

                            SizedBox(height: 50),

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
                                onChanged: (value) => setState(() => username = value),
                              ),
                            ),

                            SizedBox(height: 40),

                            // EMAIL
                            /*Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: emailController,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Correo electrónico",
                                  hintText: "Correo electrónico",
                                  icon: Icons.mail
                                ),
                                onChanged: (value) => setState(() => email = value),
                              ),
                            ),

                            SizedBox(height: 40),*/

                            // PASSWORD
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Contraseña",
                                  hintText: "Contraseña",
                                  icon: Icons.password_rounded
                                ),
                                onChanged: (value) => setState(() => password = value),
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
                                  labelText: "Repita la contraseña",
                                  hintText: "Repita la contraseña",
                                  icon: Icons.password_rounded,
                                  suffixIcon: confirmPassword.isEmpty
                                    ? null
                                    : (password == confirmPassword)
                                      ? Icon(Icons.check_circle, color: Colors.green)
                                      : Icon(Icons.cancel, color: Color.fromARGB(255, 224, 122, 95)),
                                ),
                                onChanged: (value) => setState(() => confirmPassword = value),
                              ),
                            ),

                            SizedBox(height: 60),

                            // BOTÓN
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50),
                              child: AbsorbPointer(
                                absorbing: !isFormValid,
                                child: ElevatedButton(
                                  onPressed: registerUser,
                                  style: isFormValid
                                    ? InputDecorations.defaultButton()
                                    : InputDecorations.deactivatedButton(),
                                  child: Text("Continuar"),
                                ),
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