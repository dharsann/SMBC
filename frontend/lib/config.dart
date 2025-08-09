import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get wsBaseUrl => dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8000';

  // WalletConnect (optional for mobile)
  static String? get wcProjectId => dotenv.env['WC_PROJECT_ID'];
  static String get wcAppName => dotenv.env['WC_APP_NAME'] ?? 'Blockchain Chat';
  static String get wcAppDescription => dotenv.env['WC_APP_DESCRIPTION'] ?? 'Sign in with MetaMask to chat';
  static String get wcAppUrl => dotenv.env['WC_APP_URL'] ?? 'https://example.com';
  static String get wcAppIcon => dotenv.env['WC_APP_ICON'] ?? 'https://raw.githubusercontent.com/walletconnect/walletconnect-assets/master/Logo/Blue%20(Default)/Logo.png';
}