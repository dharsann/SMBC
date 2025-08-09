import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/wallet_service.dart';
import '../services/api_client.dart';
import '../utils/ethereum_web.dart' as eth_web;
import '../widgets/metamask_hint.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _connectAndLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wallet = context.read<WalletService>();
      final api = context.read<ApiClient>();
      final session = context.read<Session>();

      final account = await wallet.connect();
      final nonceRes = await api.requestNonce(account.address);
      final message = nonceRes['message'] as String;
      final signature = await wallet.signMessage(message);

      final auth = await api.verifySignature(
        walletAddress: account.address,
        message: message,
        signature: signature,
      );

      session.setAuth(token: auth.token, user: auth.user, wallet: account.address);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEthereum = kIsWeb ? eth_web.ethereum != null : true;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sign in with MetaMask',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connect your wallet to continue. You will be asked to sign a message for authentication.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (!hasEthereum && kIsWeb) const MetaMaskHint(),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _connectAndLogin,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.account_balance_wallet),
                  label: const Text('Connect MetaMask'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}