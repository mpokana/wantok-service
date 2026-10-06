import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backendConfigured = await WantokBackend.initialize();

  runApp(WantokTechnicalControlApp(backendConfigured: backendConfigured));
}
