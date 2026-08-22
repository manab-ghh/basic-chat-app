import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/socket_provider.dart';
import 'package:frontend/routes/app_router.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is not present, ApiClient falls back to defaults.
  }
  runApp(const ProviderScope(child: ChatApp()));
}

class ChatApp extends ConsumerWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Reading (not watching) socketControllerProvider forces its
    // constructor to run once at app start, wiring the auth-state
    // listener that connects/disconnects the socket automatically.
    ref.read(socketControllerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
