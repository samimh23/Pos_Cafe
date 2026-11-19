import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hub_client.dart';
import 'lan_providers.dart';

/// App bar chip — says plainly what this POS is connected to:
/// main POS: "2 tablettes connectées"; secondary POS: "Reliée à T1" / "T1 injoignable".
class HubStatusChip extends ConsumerWidget {
  const HubStatusChip({super.key, this.compact = false});

  /// Short label ("2", "T1") when the app bar is narrow; the tooltip keeps the full text.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(posModeProvider)) {
      case PosMode.standalone:
        return const SizedBox.shrink();
      case PosMode.hub:
        final n = ref.watch(hubTabletsProvider).value ?? 0;
        return Tooltip(
          message: 'Les caisses secondaires (tablettes des serveurs) se connectent à celle-ci par le Wi-Fi.',
          child: Chip(
            key: const Key('hub-chip'),
            avatar: const Icon(Icons.tablet_android_outlined, size: 18),
            label: Text(
              compact
                  ? '$n'
                  : (n == 0
                      ? 'Aucune tablette connectée'
                      : '$n tablette${n > 1 ? 's' : ''} connectée${n > 1 ? 's' : ''}'),
            ),
          ),
        );
      case PosMode.tablet:
        final link = ref.watch(hubLinkProvider).value ?? const HubLink(HubLinkState.connecting);
        final hub = ref.watch(hubCodeProvider) ?? 'la caisse principale';
        return Tooltip(
          message:
              link.connected
                  ? 'Commandes envoyées à la caisse principale $hub (${link.address})'
                  : (link.error ?? 'Connexion…'),
          child: Chip(
            key: const Key('hub-link-chip'),
            avatar: Icon(
              link.connected ? Icons.link : Icons.link_off,
              size: 18,
              color: link.connected ? Colors.green : Colors.red,
            ),
            label: Text(
              compact ? (link.connected ? hub : '$hub ✗') : (link.connected ? 'Reliée à $hub' : '$hub injoignable'),
            ),
          ),
        );
    }
  }
}

/// Next to every screen title: PRINCIPALE (main POS) or SECONDAIRE (server tablet).
/// Nothing when the café has no main POS (this POS works on its own).
class PosRoleBadge extends ConsumerWidget {
  const PosRoleBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final (label, main) = switch (ref.watch(posModeProvider)) {
      PosMode.hub => ('PRINCIPALE', true),
      PosMode.tablet => ('SECONDAIRE', false),
      PosMode.standalone => (null, false),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      key: Key('role-badge-${label.toLowerCase()}'),
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: main ? scheme.primary : null,
        border: Border.all(color: scheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: main ? scheme.onPrimary : scheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// "Caisse terrasse · T2  [SECONDAIRE]" — the app bar title of every POS screen.
class PosTitle extends StatelessWidget {
  const PosTitle({super.key, required this.name, required this.code});
  final String name, code;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Flexible(child: Text('$name · $code', overflow: TextOverflow.ellipsis)), const PosRoleBadge()],
  );
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
