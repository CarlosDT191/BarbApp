import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/features/auth/register_email.dart';


class RegisterRole extends StatefulWidget {
  const RegisterRole({super.key});

  @override
  State<RegisterRole> createState() => _RegisterRoleState();
}

class _RegisterRoleState extends State<RegisterRole> {
  int? selectedRole;
  final List<Map<String, dynamic>> roles = [
  {"label": "Propietario", "value": 1},
  {"label": "Cliente", "value": 2},];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 23, 23, 23)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Bienvenido/a a BarbApp',
                            style: TextStyle(
                              fontSize: 33,
                              color: Color.fromARGB(255, 200, 156, 125),
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Form(
                              child: Column(
                                children: [

                  // TEXTO DE BIENVENIDA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Text('¿Qué tipo de cuenta desea crear?', style: TextStyle( fontSize: 20, color: Color.fromARGB(255, 200, 156, 125))),
                  ),

                  SizedBox(height: 60),


                  // AMBAS OPCIONES DE TIPO DE CUENTA (1 -> EMPRESA. 2-> USER)
                  Column(
                    children: roles.map((role) {
                      final isSelected = selectedRole == role["value"];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRole = role["value"];
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 200, 156, 125)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color.fromARGB(255, 200, 156, 125),
                              width: 2,
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role["label"],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color.fromARGB(255, 200, 156, 125),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                role["value"] == 1
                                    ? "Podrás automatizar el proceso de gestión de citas del local, aparecer en búsquedas de otros usuarios y analizar las estimaciones de tus ingresos."
                                    : "Podrás buscar nuevos negocios pudiendo aplicar una serie de filtros y poder realizar reservas en los locales registrados.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                SizedBox(height: 80),

                // BOTÓN DE CONTINUAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: AbsorbPointer(
                    absorbing: selectedRole == null,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterEmail(selectedRole: selectedRole)),
                      );},
                      style: selectedRole != null
                        ? InputDecorations.defaultButton()
                        : InputDecorations.deactivatedButton(),
                      child: Text("Continuar"),
                    )
                  )
                ),

                                SizedBox(height: 40)]

                              ),
                            ),
                          )
                          ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}