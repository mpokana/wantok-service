import 'package:supabase_flutter/supabase_flutter.dart';

class WantokBackendConfig {
  const WantokBackendConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.publishableKey,
    required this.publicWebUrl,
  });

  final String environment;
  final String supabaseUrl;
  final String publishableKey;
  final String publicWebUrl;

  bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  static const fromEnvironment = WantokBackendConfig(
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    publicWebUrl: String.fromEnvironment(
      'PUBLIC_WEB_URL',
      defaultValue: 'https://wantokservices.com',
    ),
  );
}

class WantokBackend {
  WantokBackend._();

  static SupabaseClient? _client;

  static bool get isInitialized => _client != null;
  static SupabaseClient? get clientOrNull => _client;

  static SupabaseClient get client {
    final value = _client;
    if (value == null) {
      throw StateError('Wantok backend is not configured.');
    }
    return value;
  }

  static Future<bool> initialize([
    WantokBackendConfig config = WantokBackendConfig.fromEnvironment,
  ]) async {
    if (_client != null) return true;
    if (!config.isConfigured) return false;

    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _client = Supabase.instance.client;
    return true;
  }
}
