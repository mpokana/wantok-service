import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';

Future<bool> sendVendorCaseReply(BuildContext context, String caseId) async {
  final entry = TextEditingController();
  final submit = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Respond to Operations'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Provide the requested clarification. Do not enter full identity or tax numbers or send document images here.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Response (10–1000 characters)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('Send response'),
        ),
      ],
    ),
  );
  final message = entry.text.trim();
  entry.dispose();
  if (submit != true) return false;
  if (message.length < 10 || message.length > 1000) {
    throw StateError('Enter 10–1000 characters.');
  }
  await WantokBackend.client.rpc(
    'respond_vendor_intake_case',
    params: {'p_case_id': caseId, 'p_response': message},
  );
  return true;
}
