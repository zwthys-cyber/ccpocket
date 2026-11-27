import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/machine.dart';
import '../../../models/protocol_version.dart';
import '../../../services/server_discovery_service.dart';
import '../../../utils/platform_helper.dart';
import '../../demo/demo_screen.dart';
import 'discovered_servers_list.dart';
import 'machine_list.dart';
import 'protocol_incompatibility_card.dart';

class ConnectForm extends StatelessWidget {
  final List<DiscoveredServer> discoveredServers;
  final VoidCallback onScanQrCode;
  final VoidCallback? onViewSetupGuide;
  final ValueChanged<DiscoveredServer> onConnectToDiscovered;

  // Machine management
  final List<MachineWithStatus> machines;
  final String? startingMachineId;
  final String? updatingMachineId;
  final String? latestBridgeVersion;
  final ValueChanged<MachineWithStatus>? onConnectToMachine;
  final ValueChanged<MachineWithStatus>? onStartMachine;
  final ValueChanged<MachineWithStatus>? onEditMachine;
  final ValueChanged<MachineWithStatus>? onDeleteMachine;
  final ValueChanged<MachineWithStatus>? onToggleFavorite;
  final ValueChanged<MachineWithStatus>? onUpdateMachine;
  final ValueChanged<MachineWithStatus>? onStopMachine;
  final VoidCallback? onAddMachine;
  final VoidCallback? onRefreshMachines;
  final ProtocolCompatibility? protocolCompatibility;

  const ConnectForm({
    super.key,
    required this.discoveredServers,
    required this.onScanQrCode,
    this.onViewSetupGuide,
    required this.onConnectToDiscovered,
    // Machine management
    this.machines = const [],
    this.startingMachineId,
    this.updatingMachineId,
    this.latestBridgeVersion,
    this.onConnectToMachine,
    this.onStartMachine,
    this.onEditMachine,
    this.onDeleteMachine,
    this.onToggleFavorite,
    this.onUpdateMachine,
    this.onStopMachine,
    this.onAddMachine,
    this.onRefreshMachines,
    this.protocolCompatibility,
  });

  bool get _hasMachineHandlers =>
      onConnectToMachine != null &&
      onStartMachine != null &&
      onEditMachine != null &&
      onDeleteMachine != null &&
      onAddMachine != null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SizedBox.square(
                              dimension: 44,
                              child: Icon(
                                Icons.terminal_rounded,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.connectToBridgeServer,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!kIsWeb && !isDesktopPlatform)
                            FilledButton.icon(
                              key: const ValueKey('scan_qr_button'),
                              onPressed: onScanQrCode,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: Text(l.scanQrCode),
                            ),
                          OutlinedButton.icon(
                            key: const ValueKey('demo_try_button'),
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(builder: (_) => const DemoScreen()),
                            ),
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text(l.demoTry),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (protocolCompatibility case final compatibility?
                  when !compatibility.isCompatible) ...[
                ProtocolIncompatibilityCard(compatibility: compatibility),
                const SizedBox(height: 16),
              ],

              // Machines section (favorites + recent)
              if (_hasMachineHandlers) ...[
                MachineList(
                  machines: machines,
                  startingMachineId: startingMachineId,
                  updatingMachineId: updatingMachineId,
                  latestBridgeVersion: latestBridgeVersion,
                  onConnect: onConnectToMachine!,
                  onStart: onStartMachine!,
                  onEdit: onEditMachine!,
                  onDelete: onDeleteMachine!,
                  onToggleFavorite: onToggleFavorite,
                  onUpdate: onUpdateMachine,
                  onStop: onStopMachine,
                  onAddMachine: onAddMachine!,
                  onRefresh: onRefreshMachines,
                ),
              ],

              // Discovered servers via mDNS
              if (discoveredServers.isNotEmpty) ...[
                const SizedBox(height: 16),
                DiscoveredServersList(
                  servers: discoveredServers,
                  onConnect: onConnectToDiscovered,
                ),
              ],

              const SizedBox(height: 24),
              if (onViewSetupGuide != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('setup_guide_button'),
                    onPressed: onViewSetupGuide,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(l.setupGuide),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
