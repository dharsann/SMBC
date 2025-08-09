import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/wallet_service.dart';
import '../services/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _connecting = false;
  bool _signing = false;
  String? _address;

  Future<void> _connectWallet() async {
    if (!kIsWeb) {
      _showError('MetaMask login is supported on web only in this build.');
      return;
    }
    setState(() => _connecting = true);
    try {
      final wallet = context.read<WalletService>();
      final account = await wallet.connect();
      setState(() => _address = account.address);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected: ${account.address}')),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _signIn() async {
    final addr = _address;
    if (addr == null) {
      _showError('Connect wallet first');
      return;
    }
    setState(() => _signing = true);
    try {
      final api = context.read<ApiClient>();
      final wallet = context.read<WalletService>();

      final nonceResp = await api.requestNonce(addr);
      final message = (nonceResp['message'] as String).trim();

      final signature = await wallet.signMessage(message);
      final auth = await api.verifySignature(
        walletAddress: addr,
        message: message,
        signature: signature,
      );

      context.read<Session>().setAuth(
            token: auth.token,
            user: auth.user,
            wallet: addr,
          );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign in with MetaMask',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _address == null
                        ? 'No wallet connected'
                        : 'Wallet: $_address',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(_connecting ? 'Connecting...' : 'Connect MetaMask'),
                    onPressed: _connecting ? null : _connectWallet,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (_address != null && !_signing) ? _signIn : null,
                    child: Text(_signing ? 'Signing...' : 'Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}