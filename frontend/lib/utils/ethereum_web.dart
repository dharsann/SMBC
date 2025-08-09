@JS('window.ethereum')
library ethereum;

import 'dart:js_interop';
import 'package:js/js.dart';

@JS()
external JSEthereumProvider? get ethereum;

extension type JSEthereumProvider(JSObject o) implements JSObject {
  external JSPromise request(RequestArgs args);
}

@JS()
@anonymous
extension type RequestArgs._(JSObject _) implements JSObject {
  external factory RequestArgs({String method, JSAny? params});
}

Future<List<String>> ethRequestAccounts() async {
  final provider = ethereum;
  if (provider == null) {
    throw Exception('MetaMask (window.ethereum) not found. Use a browser with MetaMask.');
  }
  final result = await provider.request(RequestArgs(method: 'eth_requestAccounts')).toDart;
  final arr = (result as JSArray).toDart;
  return arr.map((e) => (e as JSString).toDart).cast<String>().toList();
}

Future<String> personalSign(String message, String address) async {
  final provider = ethereum;
  if (provider == null) {
    throw Exception('MetaMask (window.ethereum) not found.');
  }
  // MetaMask expects [message, address]
  final params = JSArray();
  params.push(message.toJS);
  params.push(address.toJS);
  final result = await provider.request(RequestArgs(method: 'personal_sign', params: params)).toDart;
  return (result as JSString).toDart;
}