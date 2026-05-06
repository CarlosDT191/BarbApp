import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn buildGoogleSignIn({required List<String> scopes}) {
  final rawClientId = dotenv.env['google_token_client_id'];
  final clientId = rawClientId?.trim();
  final resolvedClientId =
      clientId == null || clientId.isEmpty ? null : clientId;

  return GoogleSignIn(
    serverClientId: resolvedClientId,
    scopes: scopes,
  );
}
