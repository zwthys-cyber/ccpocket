import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/messages.dart';
import '../../../services/bridge_service.dart';

class UsageResetCard extends StatefulWidget {
  final UsageResetCredits? credits;
  final BridgeService bridgeService;
  final VoidCallback onRefresh;

  const UsageResetCard({
    super.key,
    required this.credits,
    required this.bridgeService,
    required this.onRefresh,
  });

  @override
  State<UsageResetCard> createState() => _UsageResetCardState();
}

class _UsageResetCardState extends State<UsageResetCard> {
  bool _busy = false;
  bool _awaitingRefresh = false;

  @override
  void didUpdateWidget(covariant UsageResetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.credits != widget.credits) _awaitingRefresh = false;
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    final offset = local.timeZoneOffset;
    final zone = 'GMT${offset.isNegative ? '-' : '+'}${offset.inHours.abs()}'
        '${offset.inMinutes.abs().remainder(60) == 0 ? '' : ':${offset.inMinutes.abs().remainder(60).toString().padLeft(2, '0')}'}';
    return '${local.year}/${local.month}/${local.day} $zone '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _consume(UsageResetCredit? credit) async {
    if (_busy || _awaitingRefresh || !widget.bridgeService.isConnected) return;
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.usageResetUse),
        content: Text(l.usageResetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.usageResetUse)),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy || !widget.bridgeService.isConnected) return;
    setState(() => _busy = true);
    StreamSubscription<ServerMessage>? responseSub;
    StreamSubscription<BridgeConnectionState>? connectionSub;
    var message = l.usageResetFailed;
    var confirmedOutcome = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri.tryParse(widget.bridgeService.lastUrl ?? '');
      final storageKey = 'usage-reset-pending-${uri?.host}:${uri?.port}';
      // Reuse uncertain attempts across retries and app restarts.
      // Preserve the original target even if refreshed data changes from
      // count-only to detail rows, or the user taps a different row.
      final saved = prefs.getString(storageKey);
      final attempt = saved == null
          ? <String, dynamic>{'idempotencyKey': const Uuid().v4(), 'creditId': credit?.id}
          : jsonDecode(saved) as Map<String, dynamic>;
      final idempotencyKey = attempt['idempotencyKey'] as String;
      final targetCreditId = attempt['creditId'] as String?;
      if (!await prefs.setString(storageKey, jsonEncode(attempt))) {
        throw StateError('Could not persist reset attempt');
      }
      if (!mounted || !widget.bridgeService.isConnected) return;
      final requestId = const Uuid().v4();
      final response = Completer<UsageResetResultMessage>();
      responseSub = widget.bridgeService.messages.listen((event) {
        if (response.isCompleted) return;
        if (event is UsageResetResultMessage && event.requestId == requestId) {
          response.complete(event);
        } else if (event is ErrorMessage &&
            event.errorCode == 'unsupported_message' &&
            event.message == 'consume_usage_reset') {
          response.complete(UsageResetResultMessage(requestId: requestId, error: 'unsupported_message'));
        }
      });
      connectionSub = widget.bridgeService.connectionStatus.listen((state) {
        if (state != BridgeConnectionState.connected && !response.isCompleted) {
          response.completeError(StateError('Bridge disconnected'));
        }
      });
      widget.bridgeService.send(ClientMessage.consumeUsageReset(
        requestId: requestId,
        idempotencyKey: idempotencyKey,
        creditId: targetCreditId,
      ));
      final result = await response.future.timeout(const Duration(seconds: 30));
      confirmedOutcome = const ['reset', 'alreadyRedeemed', 'nothingToReset', 'noCredit'].contains(result.outcome);
      if (confirmedOutcome) await prefs.remove(storageKey);
      message = switch (result.outcome) {
        'reset' || 'alreadyRedeemed' => l.usageResetSuccess,
        'nothingToReset' => l.usageResetNothing,
        'noCredit' => l.usageResetNoCredit,
        _ => result.error == 'unsupported_message' || (result.error?.contains('Method not found') ?? false)
            ? l.usageResetUnsupported
            : l.usageResetFailed,
      };
    } catch (_) {
      message = l.usageResetFailed;
    } finally {
      // Cancellation stops delivery immediately; stream cleanup must not delay
      // displaying the result or refreshing the account's usage.
      unawaited(responseSub?.cancel());
      unawaited(connectionSub?.cancel());
      if (mounted) {
        setState(() {
          _busy = false;
          _awaitingRefresh = confirmedOutcome;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        widget.onRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final credits = widget.credits;
    final rows = credits?.credits ?? const <UsageResetCredit>[];
    final available = rows.where((row) => row.status == 'available' &&
        (row.expiresAt == null || row.expiresAt!.isAfter(DateTime.now()))).toList();
    final canUse = !_busy && !_awaitingRefresh && widget.bridgeService.isConnected &&
        (credits?.availableCount ?? 0) > 0;

    return Card(
      key: const ValueKey('usage_reset_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.usageResetTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (credits == null)
              Text(l.usageResetUnavailable)
            else ...[
              Text(l.usageResetCount(credits.availableCount)),
              const SizedBox(height: 4),
              Text(l.usageResetDescription),
              for (final credit in available) ...[
                const Divider(height: 24),
                Text(credit.title ?? l.usageResetOpportunity),
                if (credit.grantedAt != null) Text(l.usageResetGranted(_date(credit.grantedAt!))),
                Text(credit.expiresAt == null ? l.usageResetNoExpiry : l.usageResetExpires(_date(credit.expiresAt!))),
                TextButton(
                  onPressed: canUse ? () => _consume(credit) : null,
                  child: Text(l.usageResetUse),
                ),
              ],
              // A count may be available without detail rows. Let Codex choose
              // the next eligible credit rather than inventing credit records.
              if (credits.availableCount > 0 && available.isEmpty)
                TextButton(onPressed: canUse ? () => _consume(null) : null, child: Text(l.usageResetUse)),
              if (_busy) const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
