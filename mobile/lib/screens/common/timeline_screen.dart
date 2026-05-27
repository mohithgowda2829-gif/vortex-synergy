import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/audit_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/timeline_event.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen.resource({super.key, required this.resourceId, required this.title})
      : claimId = null;

  const TimelineScreen.claim({super.key, required this.claimId, required this.title})
      : resourceId = null;

  final String? resourceId;
  final String? claimId;
  final String title;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<TimelineEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TimelineEvent>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    final AuditApi api = AuditApi(auth.apiClient);
    if (widget.resourceId != null) {
      return api.resourceTimeline(auth.token!, widget.resourceId!);
    }
    return api.claimTimeline(auth.token!, widget.claimId!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: widget.title,
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<TimelineEvent>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<TimelineEvent>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load timeline',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.timeline_outlined,
                  action: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<TimelineEvent> events = snapshot.data!;
          if (events.isEmpty) {
            return const EmptyStateCard(
              title: 'No history available yet',
              message: 'Audit events will appear here as the resource or claim moves through its workflow.',
              icon: Icons.timeline_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SectionTitle(
                      title: widget.title,
                      subtitle: 'This audit timeline shows the verified sequence of operational actions and status changes.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...events.asMap().entries.map((MapEntry<int, TimelineEvent> entry) {
                  final int index = entry.key;
                  final TimelineEvent event = entry.value;
                  return _TimelineTile(
                    event: event,
                    showConnector: index != events.length - 1,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.showConnector,
  });

  final TimelineEvent event;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final String detailText = (event.details != null && event.details!.trim().isNotEmpty)
        ? event.details!.trim()
        : (event.metadataJson != null && event.metadataJson!.trim().isNotEmpty
            ? event.metadataJson!.trim()
            : 'No additional details recorded.');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Column(
              children: <Widget>[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _indicatorColor(event.action),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForAction(event.action),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                if (showConnector)
                  Container(
                    width: 2,
                    height: 84,
                    color: const Color(0xFFD8D1C3),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            formatStatus(event.action),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(label: formatStatus(event.action), status: event.action),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        StatusChip(label: event.targetType, status: event.targetType),
                        StatusChip(label: formatDateTime(event.createdAt)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detailText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By ${event.actorName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _indicatorColor(String action) {
    final String normalized = action.toUpperCase();
    if (normalized.contains('APPROVED') || normalized.contains('CLAIMED') || normalized.contains('DELIVERED')) {
      return const Color(0xFF0B6B2A);
    }
    if (normalized.contains('PENDING') || normalized.contains('RESERVED') || normalized.contains('TRANSIT')) {
      return const Color(0xFF9A6700);
    }
    if (normalized.contains('FAILED') || normalized.contains('REJECTED') || normalized.contains('CANCELLED') || normalized.contains('EXPIRED')) {
      return const Color(0xFFB42318);
    }
    return const Color(0xFF0F766E);
  }

  IconData _iconForAction(String action) {
    final String normalized = action.toUpperCase();
    if (normalized.contains('VERIFIED') || normalized.contains('APPROVED')) {
      return Icons.verified_rounded;
    }
    if (normalized.contains('DELIVERED') || normalized.contains('CLAIMED')) {
      return Icons.task_alt_rounded;
    }
    if (normalized.contains('TRANSIT') || normalized.contains('ASSIGNED') || normalized.contains('PICKUP')) {
      return Icons.local_shipping_rounded;
    }
    if (normalized.contains('FAILED') || normalized.contains('REJECTED') || normalized.contains('CANCELLED')) {
      return Icons.cancel_rounded;
    }
    if (normalized.contains('EXPIRED')) {
      return Icons.schedule_rounded;
    }
    return Icons.fiber_manual_record_rounded;
  }
}
