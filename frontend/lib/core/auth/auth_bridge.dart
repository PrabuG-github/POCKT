import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Bridge to sync Firebase Auth JWT with Supabase sessions.
/// This allows Supabase RLS to respect the Firebase User ID.
class AuthBridge {
  final SupabaseClient supabase = Supabase.instance.client;
  final firebase_auth.FirebaseAuth firebase = firebase_auth.FirebaseAuth.instance;

  Future<void> syncAuth() async {
    final user = firebase.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken();
      
      // We set the session manually in Supabase using the Firebase JWT.
      // NOTE: Supabase must be configured with the Firebase project's JWKS.
      await supabase.auth.setSession(idToken!);
      
      print("Synced Firebase Auth with Supabase: ${user.uid}");
    }
  }

  Future<void> signOut() async {
    await firebase.signOut();
    await supabase.auth.signOut();
  }
}
