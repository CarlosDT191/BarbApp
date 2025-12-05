import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/register.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // Aquí declaras GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      appBar: AppBar(title: Text("Iniciar Sesión"), foregroundColor: Colors.white, backgroundColor: Colors.deepOrange),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Iniciar sesión', style: TextStyle( fontSize: 35, color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(keyboardType: TextInputType.name, 
                                  decoration: InputDecoration(labelText: "Usuario", 
                                                              hintText: "Nombre de usuario", 
                                                              prefixIcon: Icon(Icons.person), 
                                                              border: OutlineInputBorder(),), 
                                  onChanged: (String value) {
                                
                                  },
                                  validator: (value){
                                    return value!.isEmpty ? "Please entry email" : null;
                                  },),
                  ),
            
                  SizedBox(height: 50,),
            
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(keyboardType: TextInputType.visiblePassword, 
                                  decoration: InputDecoration(labelText: "Contraseña", 
                                                              hintText: "Contraseña", 
                                                              prefixIcon: Icon(Icons.password), 
                                                              border: OutlineInputBorder()), 
                                  onChanged: (String value) {
                                
                                  },
                                  validator: (value){
                                    return value!.isEmpty ? "Please entry password" : null;
                                  },),
                  ),

                SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: MaterialButton(
                    minWidth: double.infinity,
                    onPressed: () {}, color: Colors.deepOrangeAccent, textColor: Colors.white, // FUNCIONAMIENTO
                    child: Text("Iniciar sesión"))
                ),

                SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.orange,
                          thickness: 2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "O",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.orange,
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: MaterialButton(
                    minWidth: double.infinity,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );}, 
                    color: Colors.deepOrangeAccent, textColor: Colors.white, // FUNCIONAMIENTO
                    child: Text("Registro"))
                ),

                SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: MaterialButton(
                    minWidth: double.infinity,
                    onPressed: loginWithGoogle,
                    color: Colors.deepOrangeAccent,
                    textColor: Colors.white, // llama a la función
                    child: Text("Iniciar sesión con Google."),
                  ),
                )
                ],

              ),
            ),
          )
          ],
      ),
    );
  }
}