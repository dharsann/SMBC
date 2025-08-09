import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'services/api_client.dart';
import 'services/wallet_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()),
        Provider<WalletService>(create: (_) => WalletService()),
        ProxyProvider<Session, ApiClient>(
          update: (_, session, __) => ApiClient(http.Client(), session),
        ),
      ],
      child: MaterialApp(
        title: 'Blockchain Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Session>(
      builder: (_, session, __) => session.isAuthenticated
          ? const HomePage()
          : const LoginPage(),
    );
  }
}