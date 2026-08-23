class AppStrings {
  AppStrings._();

  static const String appName = 'ChatApp';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String name = 'Name';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
  static const String sessionExpired = 'Session expired, please log in again.';

  // Empty states
  static const String noChatsYet = 'No conversations yet';
  static const String noChatsSubtitle = 'Search for a user to start chatting';
  static const String noMessagesYet = 'No messages yet. Say hi!';
  static const String noUsersFound = 'No users found';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  static const String settings = 'Settings';
  static const String typeMessage = 'Type a message';
}
