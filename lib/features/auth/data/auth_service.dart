class AuthService {
  // In-memory user database (pre-filled with initial demo accounts)
  static final Map<String, String> _userDatabase = {
    'user@scamshield.com': 'Password123!',
    'admin@scamshield.com': 'SecurePass2026',
  };

  /// Validates and logs in an existing user.
  static String? login({required String email, required String password}) {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      return "Please enter both email and password.";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      return "Please enter a valid email address.";
    }

    if (!_userDatabase.containsKey(cleanEmail)) {
      return "No account found with this email.";
    }

    if (_userDatabase[cleanEmail] != password) {
      return "Incorrect password. Please try again.";
    }

    return null; // Success
  }

  /// Registers a new user into the system.
  static String? register({
    required String name,
    required String email,
    required String password,
  }) {
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

    if (_userDatabase.containsKey(cleanEmail)) {
      return "An account with this email already exists.";
    }

    // Save the new user into our mock database
    _userDatabase[cleanEmail] = password;
    return null; // Success
  }
}