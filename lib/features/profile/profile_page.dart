import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/change_profile_page.dart';
import 'package:flutter_application_1/features/profile/change_password_page.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
import 'package:flutter_application_1/models/decorations.dart';

import '../../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String? firstname;
  String? lastname;
  String? email;
  bool isLoading = true;
  int _selectedIndex = 4;
  int unread = 0;
  int? role = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
    initNotifications();
    loadUserRole();
  }

  void loadUserRole() async {
    int? r = await getUserRole();
    setState(() {
      role = r;
    });
  }

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Los roles son: 0=admin, 1=propietario, 2=usuario.
  /// Retorna un `int` con el rol o `null` si no se encuentra almacenado.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  /// Maneja la navegación cuando se presiona un ícono de la barra inferior.
  ///
  /// [index] es el índice del ícono presionado, del 0 al 4 (`int`).
  ///
  /// Navega a diferentes páginas según el índice y el rol del usuario autenticado.
  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index; // Actualiza el icono seleccionado
    });

    int role = await getUserRole() ?? 0;

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
        break;
      case 1:
        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerBusinessPage()),
          );
        } else {
          print("Favoritos pulsado");
        }
        break;
      case 2:
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
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
        break;
      case 4:
        print("Perfil pulsado");
        break;
    }
  }

  /// Carga los datos del usuario actual desde el servidor.
  ///
  /// Llama a [UserService.getCurrentUser] para obtener la información del usuario
  /// y actualiza el estado con nombre, apellido y email.
  Future<void> loadUserData() async {
    try {
      final userData = await UserService.getCurrentUser();
      setState(() {
        firstname = userData['firstname'] ?? "Usuario";
        lastname = userData['lastname'] ?? "";
        email = userData['email'] ?? "correo@email.com";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      InputDecorations.showTopSnackBarError(context, "Error al cargar datos: $e");
    }
  }

  /// Realiza el cierre de sesión del usuario.
  ///
  /// Cierra la pestaña y evita que se pueda volver a la página anterior. Limpia el token y datos del usuario.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/login",
        (route) => false,
      );
      InputDecorations.showTopSnackBarInfo(context, "Sesión cerrada");
    }
  }

  /// Elimina la cuenta del usuario actual.
  ///
  /// Realiza la solicitud de eliminación al backend mediante [UserService.deleteProfile],
  /// limpia los datos locales y redirige a la pantalla de login. Muestra mensajes de éxito o error según corresponda.
  Future<void> deleteAccount() async {
    try {
      await UserService.deleteProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/login",
          (route) => false,
        );
        InputDecorations.showTopSnackBarSuccess(context, "Cuenta eliminada exitosamente");
      }
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, "Error al eliminar cuenta: $e");
      }
    }
  }

  /// Pestaña que se muestra para confirmar el cierre de sesión del usuario.
  ///
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 23, 23, 23),
        title: const Text("Cerrar sesión", style: const TextStyle(color: Colors.white)),
        content: const Text("¿Estás seguro de que quieres cerrar sesión?", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text("Cancelar", style: const TextStyle(color: Color.fromARGB(255, 200, 156, 125))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // cerrar diálogo
              logout(); // 👈 tu función de logout
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color.fromARGB(255, 30, 30, 30), // color de fondo
            ),
            child: const Text("Cerrar sesión", style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Pestaña que se muestra para confirmar la eliminación de la cuenta.
  ///
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 23, 23, 23),
        title: const Text("Eliminar cuenta", style: const TextStyle(color: Colors.white)),
        content: const Text("¿Estás seguro de que quieres eliminar tu cuenta? Toda tu información será eliminada permanentemente.", style: const TextStyle(color: Colors.white), textAlign: TextAlign.justify),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text("Cancelar", style: const TextStyle(color: Color.fromARGB(255, 200, 156, 125))),
          ),
          ElevatedButton(
            onPressed: () {
              deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color.fromARGB(255, 30, 30, 30), // color de fondo
            ),
            child: const Text("Eliminar cuenta", style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Función que recoge el número de notificaciones no leídas del almacenamiento local.
  ///
  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_notifications") ?? 0;
  }

  /// Función que inicializa el conteo de notificaciones no leídas.
  ///
  void initNotifications() async {
    await UserService.updateUnreadNotifications(); // API
    int unread = await getUnreadNotifications(); // local

    setState(() {
      this.unread = unread;
    });
  }

  @override
  Widget build(BuildContext context) {

    final primaryColor = Color.fromARGB(255, 200, 156, 125);

    if (isLoading) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 23, 23, 23),
        body: const Center(
          child: CircularProgressIndicator(color: Color.fromARGB(255, 200, 156, 125)),
        ),
        bottomNavigationBar: InputDecorations.mainBottomNavBar(
          context: context,
          currentIndex: 4,
          owner: role == 1,
          onTap: _onItemTapped,
          unreadNotifications: unread
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 23, 23, 23),

      body: Column(
        children: [

          const SizedBox(height: 90),

          // 👤 Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryColor,
            child: Icon(Icons.person_rounded, size: 50, color: Colors.black),
          ),

          const SizedBox(height: 15),

          // 🧑 Nombre
          Text(
            "$firstname $lastname",
            style: const TextStyle(fontSize: 22, color: Colors.white),
          ),

          const SizedBox(height: 10),

          // 📧 Email
          Text(
            email ?? "",
            style: const TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 40),

          // 📋 Opciones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 30, 30, 30),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  _buildOption(Icons.edit_rounded, "Editar perfil", () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangeProfilePage()),
                    );

                    if (result == true) {
                      loadUserData(); // 👈 recargar datos
                    }
                  }),
                  _buildOption(Icons.lock_rounded, "Cambiar contraseña", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                    );
                  }),
                  _buildOption(Icons.logout, "Cerrar sesión", () {
                    _showLogoutConfirmation();
                  }),
                  _buildOption(Icons.delete_forever_rounded, "Eliminar cuenta", () {
                    _showDeleteConfirmation();
                  }, mainColor: Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        context: context,
        currentIndex: 4,
        owner: role == 1,
        onTap: _onItemTapped,
        unreadNotifications: unread
      ),
    );
  }

    Widget _buildOption(IconData icon, String text, VoidCallback onTap, {Color mainColor = Colors.white,}) {
      return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: mainColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: mainColor, fontSize: 16),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                color: mainColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}