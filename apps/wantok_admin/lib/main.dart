import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wantok_api/wantok_api.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backendConfigured = await WantokBackend.initialize();

  runApp(
    ProviderScope(child: WantokAdminApp(backendConfigured: backendConfigured)),
  );
}
