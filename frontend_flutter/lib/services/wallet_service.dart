import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/ethereum_web.dart' as eth_web;

class WalletAccount {
  final String address;
  WalletAccount(this.address);
}

class WalletService {
  WalletAccount? _account;
  WalletAccount? get account => _account;

  Future<WalletAccount> connect() async {
    if (kIsWeb) {
      final accounts = await eth_web.ethRequestAccounts();
      if (accounts.isEmpty) throw Exception('No accounts returned');
      _account = WalletAccount(accounts.first);
      return _account!;
    } else {
      // TODO: Implement mobile WalletConnect v2 integration.
      throw UnimplementedError('Mobile WalletConnect integration not configured.');
    }
  }

  Future<String> signMessage(String message) async {
    if (_account == null) throw Exception('Wallet not connected');
    if (kIsWeb) {
      return eth_web.personalSign(message, _account!.address);
    } else {
      // TODO: Implement WalletConnect personal_sign on mobile.
      throw UnimplementedError('Mobile WalletConnect integration not configured.');
    }
  }
}