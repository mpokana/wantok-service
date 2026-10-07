import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'provider_discovery_page.dart';

class WantokAgentPage extends StatefulWidget {
  const WantokAgentPage({super.key});

  @override
  State<WantokAgentPage> createState() => _WantokAgentPageState();
}

class _WantokAgentPageState extends State<WantokAgentPage> {
  static const _repository = WantokAiAgentRepository();

  late Future<WantokAiAgentCapabilities> _capabilities;

  @override
  void initState() {
    super.initState();
    _capabilities = _repository.loadCapabilities();
  }

  Future<void> _refresh() async {
    final next = _repository.loadCapabilities();
    setState(() => _capabilities = next);
    try {
      await next;
    } catch (_) {}
  }

  void _openProviderSearch([String? query]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProviderDiscoveryPage(initialQuery: query),
      ),
    );
  }

  Future<void> _requestHumanHelp() async {
    final summary = await showDialog<String>(
      context: context,
      builder: (context) => const _HumanHelpDialog(),
    );
    if (summary == null || summary.trim().isEmpty) return;

    try {
      await _repository.requestHumanHandoff(
        summary: summary,
        context: const {'source': 'wantok_ai_agent', 'chat_enabled': false},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your help request was sent for human follow-up.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  void _showListingHelpPreview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Provider listing assistance will be enabled with the Marketplace and AI gateway phases.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text(
          'Wantok Agent',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<WantokAiAgentCapabilities>(
        future: _capabilities,
        builder: (context, snapshot) {
          final capabilities = snapshot.data;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5F2A7A),
                      Color(0xFF0B79A8),
                      Color(0xFF075C3A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Wantok guide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Find services, products and providers, or get help when you are not sure where to start.',
                            style: TextStyle(
                              color: Color(0xFFF0F6F4),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 33,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (snapshot.hasError)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.cloud_off_outlined,
                      color: WantokColors.coral,
                    ),
                    title: const Text(
                      'Agent status unavailable',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Provider search still works. AI chat remains disabled.',
                    ),
                    trailing: IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                )
              else
                _AgentStatusCard(capabilities: capabilities!),
              const SizedBox(height: 18),
              const Text(
                'Try one of these',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _PromptTile(
                icon: Icons.plumbing_rounded,
                title: 'Find a plumber',
                subtitle: 'Search approved plumbing providers.',
                onTap: () => _openProviderSearch('plumber'),
              ),
              _PromptTile(
                icon: Icons.directions_car_filled_rounded,
                title: 'Show top-rated vehicle hire',
                subtitle: 'Search providers offering vehicle-hire services.',
                onTap: () => _openProviderSearch('vehicle hire'),
              ),
              _PromptTile(
                icon: Icons.storefront_outlined,
                title: 'Help me list a product',
                subtitle: 'Marketplace listing assistance is prepared for the next commerce phase.',
                onTap: _showListingHelpPreview,
              ),
              _PromptTile(
                icon: Icons.search_off_rounded,
                title: 'I cannot find the service I need',
                subtitle:
                    'Search providers first, or ask a real person for help.',
                onTap: _openProviderSearch,
              ),
              const SizedBox(height: 18),
              Card(
                color: const Color(0xFFFFF7EE),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFFFE5DA),
                            child: Icon(
                              Icons.support_agent_rounded,
                              color: WantokColors.clay,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Need a real person?',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'If normal search cannot solve the problem, send a short help request for human follow-up. Live human chat is not enabled yet.',
                        style: TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: capabilities?.handoffCaptureEnabled == true
                              ? _requestHumanHelp
                              : null,
                          icon: const Icon(Icons.support_agent_rounded),
                          label: const Text('Talk to a person'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                enabled: capabilities?.chatEnabled == true,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Ask Wantok Agent',
                  hintText: capabilities?.chatEnabled == true
                      ? 'What can I help you find?'
                      : 'AI chat is not enabled yet.',
                  prefixIcon: const Icon(Icons.auto_awesome_outlined),
                  suffixIcon: const Icon(Icons.send_rounded),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wantok Agent uses controlled Wantok APIs. It cannot approve providers, move money, grant privileged roles or bypass workflow approvals.',
                style: TextStyle(
                  color: WantokColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AgentStatusCard extends StatelessWidget {
  const _AgentStatusCard({required this.capabilities});

  final WantokAiAgentCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: capabilities.chatEnabled
                  ? const Color(0xFFE3F4EA)
                  : const Color(0xFFF2ECF7),
              child: Icon(
                capabilities.chatEnabled
                    ? Icons.smart_toy_rounded
                    : Icons.construction_rounded,
                color: capabilities.chatEnabled
                    ? WantokColors.primaryDark
                    : WantokColors.purplePay,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capabilities.chatEnabled
                        ? 'AI chat is available'
                        : 'AI chat is being prepared',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    capabilities.chatEnabled
                        ? 'The configured Wantok AI gateway is ready.'
                        : 'Provider search and human help requests are available now. A model provider has not been connected.',
                    style: const TextStyle(
                      color: WantokColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F4ED),
          child: Icon(icon, color: WantokColors.primaryDark),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _HumanHelpDialog extends StatefulWidget {
  const _HumanHelpDialog();

  @override
  State<_HumanHelpDialog> createState() => _HumanHelpDialogState();
}

class _HumanHelpDialogState extends State<_HumanHelpDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ask a person for help'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 4,
        maxLines: 7,
        maxLength: 4000,
        decoration: const InputDecoration(
          labelText: 'What do you need help with?',
          hintText: 'Example: I need a generator technician in Lae but cannot find the service.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send request'),
        ),
      ],
    );
  }
}

String _friendlyError(Object error) {
  return error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('PostgrestException(message: ', '');
}
