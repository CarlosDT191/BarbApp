import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:http/http.dart' as http;


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int? selectedRole;
  final List<Map<String, dynamic>> roles = [
  {"label": "Propietario", "value": 1},
  {"label": "Cliente", "value": 2},];

  String password = "";
  String confirmPassword = "";
  String email= "";
  String username= "";

  Future<void> registerUser() async {
  final url = Uri.parse("http://10.0.2.2:3000/auth/register");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "username": username,
      "password": password,
      "role": selectedRole
    }),
  );

    print("Enviando cositas a la BD");

    if (response.statusCode == 200) {
      setState(() {
        errorMessage = null;
      });
      Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro"), foregroundColor: Colors.white, backgroundColor: Colors.deepOrange),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Registro', style: TextStyle( fontSize: 35, color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [
                  
                  // Mensaje de error del BackEnd
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // DropdownButton para opciones prefijadas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Elige el tipo de cuenta',
                      ),
                      value: selectedRole,
                      items: roles.map((role) {
                        return DropdownMenuItem<int>(
                          value: role["value"],
                          child: Text(role["label"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(keyboardType: TextInputType.name, 
                                  decoration: InputDecoration(labelText: "Nombre de usuario", 
                                                              hintText: "Nombre de usuario", 
                                                              prefixIcon: Icon(Icons.person), 
                                                              border: OutlineInputBorder(),), 
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(keyboardType: TextInputType.name, 
                                  decoration: InputDecoration(labelText: "Correo electrónico", 
                                                              hintText: "Correo electrónico", 
                                                              prefixIcon: Icon(Icons.mail), 
                                                              border: OutlineInputBorder(),), 
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

                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            password = value;
                          });
                        },
                      ),
                    ),

                  SizedBox(height: 50),

                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Repita la contraseña",
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                          suffixIcon: (confirmPassword.isEmpty)
                              ? null
                              : (password == confirmPassword)
                                  ? Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : Icon(Icons.cancel,
                                      color: Colors.red),
                        ),
                        onChanged: (value) {
                          setState(() {
                            confirmPassword = value;
                          });
                        },
                      ),
                    ),

                SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: MaterialButton(
                    minWidth: double.infinity,
                    onPressed: () {registerUser();}, 
                    color: Colors.deepOrangeAccent, textColor: Colors.white, // FUNCIONAMIENTO
                    child: Text("Registro"))
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