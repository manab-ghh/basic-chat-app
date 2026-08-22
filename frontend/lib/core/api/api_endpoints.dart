/// All backend endpoint paths in one place. If the backend's route
/// structure changes, this is the single file to update.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Users
  static const String users = '/users';
  static const String searchUsers = '/users/search';
  static const String updateProfile = '/users/profile';

  // Chats
  static const String chats = '/chats';

  static const String uploadAvatar = '/users/avatar';

  // Messages (nested under chats on the backend)
  static String messages(String chatId) => '/chats/$chatId/messages';
  static const String sendMessage = '/chats/messages';
}
