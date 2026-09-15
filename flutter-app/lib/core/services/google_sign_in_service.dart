import 'package:google_sign_in/google_sign_in.dart';

abstract class IGoogleSignInProvider {
  Future<String?> signInAndGetIdToken();
  Future<void> signOut();
}

class GoogleSignInProvider implements IGoogleSignInProvider {
  final GoogleSignIn _googleSignIn;

  GoogleSignInProvider({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId:
                  '630204984694-gr3448trnltr6gkuoikcknhac17il54u.apps.googleusercontent.com',
              scopes: ['email', 'profile'],
            );

  @override
  Future<String?> signInAndGetIdToken() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      // User cancelled the account chooser
      return null;
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    return auth.idToken;
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
