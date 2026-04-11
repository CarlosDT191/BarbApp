import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/change_profile_page.dart';
import 'package:flutter_application_1/features/profile/change_password_page.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
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

  @override
  void initState() {
    super.initState();
    loadUserData();
    initNotifications();
  }

  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

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
        print("Estrella pulsado");
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

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

  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_notifications") ?? 0;
  }

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
          currentIndex: 4,
          owner: false,
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
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        currentIndex: 4,
        owner: false,
        onTap: _onItemTapped,
        unreadNotifications: unread
      ),
    );
  }

  Widget _buildOption(IconData icon, String text, VoidCallback onTap) {
    return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
  }
}