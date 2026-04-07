import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    loadUserData();
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

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: firstname);
    final lastNameController = TextEditingController(text: lastname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: "Apellido"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await UserService.updateProfile(
                  firstname: nameController.text,
                  lastname: lastNameController.text,
                );

                setState(() {
                  firstname = nameController.text;
                  lastname = lastNameController.text;
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perfil actualizado exitosamente")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar Contraseña"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña Actual"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Nueva Contraseña"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmar Nueva Contraseña"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await UserService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmPasswordController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contraseña actualizada exitosamente")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            child: const Text("Cambiar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final primaryColor = Color.fromARGB(255, 200, 156, 125);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mi cuenta"),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Color.fromARGB(255, 23, 23, 23),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi cuenta"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Color.fromARGB(255, 23, 23, 23),

      body: Column(
        children: [

          const SizedBox(height: 30),

          // 👤 Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryColor,
            child: Icon(Icons.person, size: 50, color: Colors.black),
          ),

          const SizedBox(height: 15),

          // 🧑 Nombre
          Text(
            "$firstname $lastname",
            style: const TextStyle(fontSize: 22, color: Colors.white),
          ),

          const SizedBox(height: 5),

          // 📧 Email
          Text(
            email ?? "",
            style: const TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 30),

          // 📋 Opciones
          Expanded(
            child: ListView(
              children: [

                _buildOption(Icons.edit, "Editar perfil", () {
                  _showEditProfileDialog();
                }),

                _buildOption(Icons.lock, "Cambiar contraseña", () {
                  _showChangePasswordDialog();
                }),

                _buildOption(Icons.logout, "Cerrar sesión", () {
                  logout();
                }),

              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54),
      onTap: onTap,
    );
  }
}