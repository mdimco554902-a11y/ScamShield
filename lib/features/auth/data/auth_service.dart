import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream listening to real-time auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get currently signed-in user
  User? get currentUser => _auth.currentUser;

  /// Validates and logs in an existing user using Firebase Auth.
  Future<String?> login({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      return "Please enter both email and password.";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      return "Please enter a valid email address.";
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "No account found with this email.";
        case 'wrong-password':
          return "Incorrect password. Please try again.";
        case 'invalid-credential':
          return "Invalid credentials. Please check your email and password.";
        case 'user-disabled':
          return "This user account has been disabled.";
        case 'too-many-requests':
          return "Too many failed attempts. Please try again later.";
        default:
          return e.message ?? "An error occurred during sign in.";
      }
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  /// Registers a new user with Firebase Auth and updates display name.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty) {
      return "Please enter your full name.";
    }

    if (cleanEmail.isEmpty || password.isEmpty) {
      return "Please fill out all fields.";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      return "Please enter a valid email address.";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters long.";
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      // Store the user's full name in Firebase Auth profile
      await userCredential.user?.updateDisplayName(name.trim());
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "An account with this email already exists.";
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'weak-password':
          return "Password is too weak. Please choose a stronger password.";
        default:
          return e.message ?? "An error occurred during registration.";
      }
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}