import 'package:flutter/material.dart';

class ClientLoadError extends StatelessWidget {
  const ClientLoadError({
    required this.title,
    required this.onRetry,
    super.key,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    ],
  );
}
