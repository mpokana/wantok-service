import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wantok_api/wantok_api.dart';

import 'src/app.dart';
import 'src/phone_preview/phone_preview_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Explicitly isolated offline phone-design beta. Do not initialise Supabase.
  // This flag defaults OFF and is never used by the normal client release.
  const previewOnly = bool.fromEnvironment(
    'WANTOK_PHONE_PREVIEW',
    defaultValue: false,
  );
  if (previewOnly) {
    runApp(const WantokPhonePreviewApp());
    return;
  }
  final backendConfigured = await WantokBackend.initialize();

  runApp(ProviderScope(child: WantokApp(backendConfigured: backendConfigured)));
}
