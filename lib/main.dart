import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


// MAIN DE LA APLICACIÓN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// STATEFULL DE LA PÁGINA COMPLETA
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Estado de la aplicación
class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  // Se llama solo cuando se inicia la aplicación
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // SharedPreferences permite guardar datos de forma local
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool("isLoggedIn") ?? false;

    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  // Método de login exitoso
  void _loginSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", true);
    setState(() {
      _isLoggedIn = true;
    });
  }

  // Build permite mostrar qué página dependiendo del almacenamiento local
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(home: Center(child: CircularProgressIndicator()));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primaryColor: Colors.orange,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    ),
      // home: _isLoggedIn ? HomePage() : LoginPage(onLogin: _loginSuccess), ESTO HAY QUE DESACTIVARLO EN LA LÓGICA PRINCIPAL
      home: LoginPage(onLogin: _loginSuccess)
    );
  }
}
