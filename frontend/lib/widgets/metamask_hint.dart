import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MetaMaskHint extends StatelessWidget {
  const MetaMaskHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('MetaMask extension not detected.'),
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://metamask.io/download/')),
          child: const Text('Install MetaMask'),
        ),
      ],
    );
  }
}