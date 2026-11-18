import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hub_client.dart';
import 'lan_providers.dart';

/// App bar chip: "Hub · 2 tablettes" on the main POS, "Caisse principale ✓/✗" on a tablet.
class HubStatusChip extends ConsumerWidget {
  const HubStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(posModeProvider)) {
      case PosMode.standalone:
        return const SizedBox.shrink();
      case PosMode.hub:
        final n = ref.watch(hubTabletsProvider).value ?? 0;
        return Tooltip(
          message: 'Caisse principale : les tablettes des serveurs se connectent à elle par le Wi-Fi.',
          child: Chip(
            key: const Key('hub-chip'),
            avatar: const Icon(Icons.hub_outlined, size: 18),
            label: Text('Hub · $n tablette${n > 1 ? 's' : ''}'),
          ),
        );
      case PosMode.tablet:
        final link = ref.watch(hubLinkProvider).value ?? const HubLink(HubLinkState.connecting);
        return Tooltip(
          message: link.connected ? 'Connectée à la caisse principale (${link.address})' : (link.error ?? 'Connexion…'),
          child: Chip(
            key: const Key('hub-link-chip'),
            avatar: Icon(
              link.connected ? Icons.link : Icons.link_off,
              size: 18,
              color: link.connected ? Colors.green : Colors.red,
            ),
            label: Text(link.connected ? 'Caisse principale' : 'Caisse principale injoignable'),
          ),
        );
    }
  }
}

/// On a server tablet: a clear warning when the Hub can't be reached
/// (orders can't be sent; what's on screen may be out of date).
class HubLinkBanner extends ConsumerWidget {
  const HubLinkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(posModeProvider) != PosMode.tablet) return const SizedBox.shrink();
    final link = ref.watch(hubLinkProvider).value ?? const HubLink(HubLinkState.connecting);
    if (link.connected) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('hub-banner'),
      color: link.state == HubLinkState.connecting ? scheme.secondaryContainer : scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(link.state == HubLinkState.connecting ? Icons.sync : Icons.wifi_off),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                link.state == HubLinkState.connecting
                    ? 'Connexion à la caisse principale…'
                    : '${link.error ?? 'Caisse principale injoignable.'} Les commandes ne peuvent pas être envoyées.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
