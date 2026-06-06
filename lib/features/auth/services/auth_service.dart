import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //create a new account
  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  //get the current logged-in user
  User? get currentUser => _auth.currentUser;

  //stream that emits whenever auth state changes (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
