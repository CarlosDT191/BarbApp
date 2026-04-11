import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class InputDecorations {

  static InputDecoration defaultInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    double rightPadding = 23;

    // 🔍 Detectar si es icono de visibilidad
    if (suffixIcon is IconButton) {
      final iconWidget = suffixIcon.icon;

      if (iconWidget is Icon) {
        if (iconWidget.icon == Icons.visibility_rounded ||
            iconWidget.icon == Icons.visibility_off_rounded) {
          rightPadding = 10; // 👈 padding reducido
        }
      }
  }
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      // AQUÍ CAMBIAMOS EL COLOR DEL ICONO
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 18, right: 8), // ajusta la posición horizontal
        child: Icon(icon, color: Color.fromARGB(255, 200, 156, 125)),
      ),

      suffixIcon: suffixIcon != null
        ? Padding(
            padding: EdgeInsets.only(right: rightPadding), // 👈 ajusta esto
            child: suffixIcon,
          )
        : null,

      labelStyle: TextStyle(
        color: Colors.grey, // label cuando NO está seleccionado
      ),

      floatingLabelStyle: TextStyle(
        color: Color.fromARGB(255, 200, 156, 125), // label cuando escribes
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Color.fromARGB(255, 200, 156, 125)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Color.fromARGB(255, 200, 156, 125), width: 2),
      ),
    );
  }

  static ButtonStyle defaultButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 200, 156, 125),
      foregroundColor: Colors.white,
      minimumSize: const Size(500, 50),
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(                 // borde del botón
          color: Colors.white,            // color del borde
          width: 1,                       // grosor del borde
        ),
      ),
    );
  }

  static Widget loadingButton({
    required bool isSent,
    required bool isEnabled,
    required VoidCallback onPressed,
    required String text,
  }) {
    return AbsorbPointer(
      absorbing: !isEnabled || isSent,
      child: ElevatedButton(
        onPressed: (!isEnabled || isSent) ? null : onPressed,
        style: isEnabled
            ? defaultButton()
            : deactivatedButton(),
        child: isSent
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(text),
      ),
    );
  }


 static ButtonStyle deactivatedButton() {
    return ButtonStyle(
      minimumSize: MaterialStateProperty.all(const Size(500, 50)),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        return const Color.fromARGB(60, 200, 156, 125);
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return Colors.grey;
      }),
    );
  }


  static ButtonStyle borderButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 23, 23, 23),
      foregroundColor: Colors.white,
      minimumSize: const Size(500, 50),
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(                 // 👈 borde del botón
          color: const Color.fromARGB(255, 85, 83, 83),            // color del borde
          width: 2,                       // grosor del borde
        )
      ),
    );
  }

  /* =============================================================================
          FUNCIONES SOBRE MENSAJES DE ERROR PERSONALIZADOS TRAS ACCIONES 
    ==============================================================================
  */
  static void showTopSnackBarSuccess(BuildContext context, String message) {
    Flushbar(
      messageText: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.white, 
            size: 28,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      margin: const EdgeInsets.all(0),
      borderRadius: BorderRadius.circular(0),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      padding: const EdgeInsets.all(30),
    ).show(context);
  }

  static void showTopSnackBarError(BuildContext context, String message) {
    Flushbar(
      messageText: Row(
        children: [
          const Icon(
            Icons.report_gmailerrorred_rounded,
            color: Colors.white, 
            size: 28,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      margin: const EdgeInsets.all(0),
      borderRadius: BorderRadius.circular(0),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      padding: const EdgeInsets.all(30),
    ).show(context);
  }

  static void showTopSnackBarInfo(BuildContext context, String message) {
    Flushbar(
      messageText: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white, 
            size: 28,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blueAccent,
      margin: const EdgeInsets.all(0),
      borderRadius: BorderRadius.circular(0),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      padding: const EdgeInsets.all(30),
    ).show(context);
  }

  static Widget mainBottomNavBar({
    required int currentIndex,
    required Function(int) onTap,
    bool owner = false,
    int unreadNotifications = 0,
    }) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
          ),
        ),
        child: SizedBox(
          height: 125,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromARGB(255, 23, 23, 23),
            selectedItemColor: const Color.fromARGB(255, 200, 156, 125),
            unselectedItemColor: Colors.grey,
            currentIndex: currentIndex,
            iconSize: 40,
            onTap: onTap,
            items: [
              BottomNavigationBarItem(
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.calendar_month_rounded),
                  ],
                ),
                label: "",
              ),

              BottomNavigationBarItem(
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      owner ? Icons.home_work_rounded : Icons.star_rate_rounded,
                    ),
                  ],
                ),
                label: "",
              ),

              BottomNavigationBarItem(
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.map_rounded, size: 65),
                  ],
                ),
                label: "",
              ),

              BottomNavigationBarItem(
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        const Icon(Icons.notifications_rounded),

                        if (unreadNotifications > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                unreadNotifications > 99
                                    ? '99+'
                                    : unreadNotifications.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                label: "",
              ),

              BottomNavigationBarItem(
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_rounded),
                  ],
                ),
                label: "",
              ),
            ],
          ),
        ),
      );
    }

    static Widget buildNotificationIconWithBadge(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications),

        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}