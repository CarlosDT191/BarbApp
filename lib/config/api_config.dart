import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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