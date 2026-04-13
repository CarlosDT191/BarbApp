import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Obtiene la URL base de la API según el entorno y plataforma.
///
/// En modo release usa la IP de la red local para conectarse desde dispositivos físicos.
/// En modo debug usa localhost (emulador) o IP local (dispositivo físico).
///
/// Retorna un `String` con la URL base de la API del backend.
String getApiBaseUrl() {
  if (kReleaseMode) {
    // App compilada en modo release (APK o IPA)
    // Usa la IP de tu PC en la misma red Wi-Fi
    return dotenv.env['URL_LAN']!;
  } else {
    // App corriendo en modo debug (emulador)
    if (Platform.isAndroid) {
      return dotenv.env['URL_AS']!;
    } else if (Platform.isIOS) {
      return dotenv.env['URL_LH']!;
    } else {
      return dotenv.env['URL_LH']!; // web
    }
  }
}