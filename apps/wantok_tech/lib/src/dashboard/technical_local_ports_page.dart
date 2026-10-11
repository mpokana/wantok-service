import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// A reference list of EAGLT02 loopback-only development entry points.
///
/// These are not network probes, health metrics, public URLs or credentials.
@immutable
class LocalWantokApplication {
  const LocalWantokApplication({
    required this.port,
    required this.name,
    required this.description,
    required this.environment,
    required this.icon,
  });

  final int port;
  final String name;
  final String description;
  final String environment;
  final IconData icon;

  Uri get uri => Uri(scheme: 'http', host: '127.0.0.1', port: port, path: '/');
}

const localWantokApplications = <LocalWantokApplication>[
  LocalWantokApplication(
    port: 3000,
    name: 'Wantok Services Client',
    description:
        'Customer website: services, providers, Track, Wallet and Inbox.',
    environment: 'Main development',
    icon: Icons.storefront_outlined,
  ),
  LocalWantokApplication(
    port: 3100,
    name: 'Technical Control',
    description: 'Technical modules, permissions and Theme & Media.',
    environment: 'Main development',
    icon: Icons.settings_input_component_outlined,
  ),
  LocalWantokApplication(
    port: 3200,
    name: 'Operations Admin',
    description:
        'Business operations, provider approvals and Support & Inquiries.',
    environment: 'Main development',
    icon: Icons.admin_panel_settings_outlined,
  ),
  LocalWantokApplication(
    port: 3300,
    name: 'Client staging',
    description: 'Separate Client build for review before updating port 3000.',
    environment: 'Staging preview',
    icon: Icons.preview_outlined,
  ),
  LocalWantokApplication(
    port: 3400,
    name: 'Technical staging',
    description:
        'Separate Technical build for review before updating port 3100.',
    environment: 'Staging preview',
    icon: Icons.tune_outlined,
  ),
];

typedef LocalUrlOpener = Future<bool> Function(Uri url);

/// Visible only through the authenticated Technical Platform Admin shell.
class TechnicalLocalPortsPage extends StatelessWidget {
  const TechnicalLocalPortsPage({super.key, this.openUrl = launchUrl});

  final LocalUrlOpener openUrl;

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final opened = await openUrl(uri);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the local address.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the local address.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local applications & ports')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Wantok Services — EAGLT02',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'These are five local development and staging addresses on '
                'EAGLT02. They are not production websites. Each button '
                'opens the address on the device running this browser.',
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: WantokColors.primaryDark),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '127.0.0.1 means this computer. To open EAGLT02 '
                          'services, use a browser on EAGLT02. On a phone '
                          'or a different PC these links point to that '
                          'device instead. Opening a link is a manual '
                          'availability check; no live-health monitoring '
                          'is implied.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final endpoint in localWantokApplications)
                Card(
                  key: ValueKey('local-port-${endpoint.port}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            endpoint.icon,
                            size: 30,
                            color: WantokColors.primaryDark,
                          ),
                          SizedBox(
                            width: constraints.maxWidth >= 700
                                ? 530
                                : constraints.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${endpoint.name} · ${endpoint.port}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(endpoint.description),
                                const SizedBox(height: 6),
                                SelectableText(
                                  endpoint.uri.toString(),
                                  style: const TextStyle(
                                    color: WantokColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  endpoint.environment,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: WantokColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            key: ValueKey('open-local-port-${endpoint.port}'),
                            onPressed: () => _open(context, endpoint.uri),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Staging ports 3300 and 3400 are preview builds. '
                'Their presence does not mean the same changes have '
                'been deployed to the main development ports. '
                'Do not expose these local development ports to the '
                'public internet.',
                style: TextStyle(color: WantokColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
