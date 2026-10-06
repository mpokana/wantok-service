import 'wantok_backend.dart';

class WantokAiAgentCapabilities {
  const WantokAiAgentCapabilities({
    required this.enabled,
    required this.chatEnabled,
    required this.providerConfigured,
    required this.handoffCaptureEnabled,
    required this.humanLiveChatEnabled,
    required this.tools,
    required this.restrictedActions,
  });

  final bool enabled;
  final bool chatEnabled;
  final bool providerConfigured;
  final bool handoffCaptureEnabled;
  final bool humanLiveChatEnabled;
  final List<String> tools;
  final List<String> restrictedActions;

  factory WantokAiAgentCapabilities.fromMap(Map<String, dynamic> row) {
    return WantokAiAgentCapabilities(
      enabled: row['enabled'] as bool? ?? false,
      chatEnabled: row['chat_enabled'] as bool? ?? false,
      providerConfigured: row['provider_configured'] as bool? ?? false,
      handoffCaptureEnabled: row['handoff_capture_enabled'] as bool? ?? false,
      humanLiveChatEnabled: row['human_live_chat_enabled'] as bool? ?? false,
      tools: _stringList(row['tools']),
      restrictedActions: _stringList(row['restricted_actions']),
    );
  }
}

class WantokAiAgentRepository {
  const WantokAiAgentRepository();

  Future<WantokAiAgentCapabilities> loadCapabilities() async {
    final result = await WantokBackend.client.rpc(
      'get_wantok_ai_agent_capabilities',
    );
    return WantokAiAgentCapabilities.fromMap(_mapValue(result));
  }

  Future<String> requestHumanHandoff({
    required String summary,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final result = await WantokBackend.client.rpc(
      'request_wantok_ai_handoff',
      params: {'p_summary': summary.trim(), 'p_context': context},
    );
    return result.toString();
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return <String, dynamic>{};
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}
