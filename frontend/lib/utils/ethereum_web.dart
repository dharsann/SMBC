@js.JS()
library ethereum_web;

import 'dart:js_util' as js_util;
import 'dart:js_interop' as js;

@js.JS('window.ethereum')
external Object? get _ethereum;

Future<List<String>> ethRequestAccounts() async {
  final provider = _ethereum;
  if (provider == null) {
    throw Exception('MetaMask (window.ethereum) not found. Use a browser with MetaMask.');
  }
  final result = await js_util.promiseToFuture(js_util.callMethod(provider, 'request', [
    js_util.jsify({'method': 'eth_requestAccounts'})
  ]));
  final list = List<dynamic>.from(result as List);
  return list.map((e) => e.toString()).toList();
}

Future<String> personalSign(String message, String address) async {
  final provider = _ethereum;
  if (provider == null) {
    throw Exception('MetaMask (window.ethereum) not found.');
  }
  final result = await js_util.promiseToFuture(js_util.callMethod(provider, 'request', [
    js_util.jsify({
      'method': 'personal_sign',
      'params': [message, address]
    })
  ]));
  return result.toString();
}