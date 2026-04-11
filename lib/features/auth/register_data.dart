import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
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

Future<void> saveUserSessions(String token, int role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("token", token);
  await prefs.setInt("role", role);
}

class _RegisterPageState extends State<RegisterPage> {
  String firstname= "";
  String lastname= "";
  String password = "";
  String confirmPassword = "";
  bool isSent = false;
  bool _obscurePassword = true;

  bool get isFormValid => firstname.isNotEmpty && lastname.isNotEmpty && password.isNotEmpty &&
    confirmPassword.isNotEmpty && (password == confirmPassword);

  Future<void> registerUser() async {
    setState(() => isSent = true);
    final apiBaseUrl = getApiBaseUrl();
    final url = Uri.parse("$apiBaseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
          "email": widget.email,
          "firstname": firstname,
          "lastname" : lastname,
          "password": password,
          "role": widget.selectedRole
        }),
      );

      if (response.statusCode == 200) {

        final Map<String, dynamic> data = jsonDecode(response.body);

        String userToken = data["token"];
        int role = data["user"]["role"];
        saveUserSessions(userToken, role);

        setState(() {
          errorMessage = null;
        });

        // Quitamos de la pila el register_first, el register_email y el register_second
        for(int i=0; i<3; ++i){
          Navigator.pop(context);
        } 

        // PROPIETARIO
        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageOwner()),
          );
        } 
        // CLIENTE
        else {
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

      setState(() => isSent = false);
  }

  String? errorMessage;
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
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

                            SizedBox(height: 50),

                            // USERNAME
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

                            // EMAIL
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


                            SizedBox(height: 40),

                            // PASSWORD
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecorations.defaultInputDecoration(
                                  labelText: "Contraseña",
                                  hintText: "Contraseña",
                                  icon: Icons.password_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Color.fromARGB(255, 200, 156, 125),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
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
                                text: "Continuar",
                                onPressed: registerUser,
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