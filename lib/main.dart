import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'features/chat/presentation/screens/threads_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.isConfigured) {
    await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);
  }
  runApp(const ProviderScope(child: MarketplaceChatApp()));
}

class MarketplaceChatApp extends StatelessWidget {
  const MarketplaceChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Chat',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Color(0xFF7AAAFF)),
      ),
      home: Config.isConfigured
          ? const ThreadsScreen()
          : const _ConfigMissingScreen(),
    );
  }
}

class _ConfigMissingScreen extends StatelessWidget {
  const _ConfigMissingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define to run this app.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
