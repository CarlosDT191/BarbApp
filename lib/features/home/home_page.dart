import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Página Principal")),
      body: Center(
        child: Text("Bienvenido 🚀", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
