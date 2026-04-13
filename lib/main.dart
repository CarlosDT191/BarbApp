import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Punto de entrada principal de la aplicación Flutter.
///
/// Inicializa Firebase, carga variables de entorno y configura la orientación
/// de la pantalla en modo portrait. Ejecuta la aplicación con [runApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: "assets/.env");

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

  /// Inicializa el estado cuando la aplicación inicia.
  ///
  /// Verifica si el usuario estaba autenticado en una sesión anterior
  /// llamando a [_checkLogin].
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  /// Verifica si el usuario estaba autenticado en sesiones previas.
  ///
  /// Utiliza [SharedPreferences] para recuperar el estado de autenticación
  /// guardado localmente. Actualiza el estado con los valores recuperados.
  Future<void> _checkLogin() async {
    // SharedPreferences permite guardar datos de forma local
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool("isLoggedIn") ?? false;

    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  /// Actualiza el estado cuando el login es exitoso.
  ///
  /// Guarda el estado autenticado en [SharedPreferences] para que
  /// persista entre ejecuciones de la aplicación.
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

      locale: const Locale('es', 'ES'),

      supportedLocales: const [
        Locale('es', 'ES'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 23, 23, 23),
        primaryColor: Color.fromARGB(255, 23, 23, 23),
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 23, 23, 23)),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(255, 23, 23, 23), width: 2),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white), 
        ),
      ),
      home: _isLoggedIn ? HomePage() : LoginPage(onLogin: _loginSuccess), // Habría que habilitar la opción dependiendo si se inicia la cuenta como Cliente o como Propietario
      routes: {
        '/login': (context) => LoginPage(onLogin: _loginSuccess),
        '/home': (context) => HomePage(),
      },
    );
  }
}
