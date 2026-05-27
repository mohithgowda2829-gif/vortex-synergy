import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/delivery_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/claim_item.dart';
import '../../models/delivery_task.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';
import '../common/timeline_screen.dart';
import 'assign_delivery_screen.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key, required this.claim});

  final ClaimItem claim;

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  static const List<String> _workflow = <String>[
    'ASSIGNED',
    'PICKUP_PENDING',
    'PICKUP_APPROVED',
    'IN_TRANSIT',
    'DELIVERED',
  ];

  late Future<DeliveryTask?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DeliveryTask?> _load() async {
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      return await DeliveryApi(auth.apiClient).byClaim(auth.token!, widget.claim.id);
    } catch (error) {
      if (AppFeedback.messageFromError(error).contains('Delivery not found')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Delivery Tracking',
      onLogout: () => auth.logout(),
      child: FutureBuilder<DeliveryTask?>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<DeliveryTask?> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load delivery progress',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.local_shipping_outlined,
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

          final DeliveryTask? delivery = snapshot.data;
          if (delivery == null) {
            return RefreshIndicator(
              onRefresh: () async => setState(() => _future = _load()),
              child: ListView(
                children: <Widget>[
                  EmptyStateCard(
                    title: 'No delivery assigned yet',
                    message: 'Assign an agent, vehicle, and order number to start receiver-managed delivery.',
                    icon: Icons.local_shipping_outlined,
                    action: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openAssignment,
                        child: const Text('Assign Delivery Agent'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SectionTitle(
                          title: delivery.resourceTitle,
                          subtitle: _statusMessage(delivery.status),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            StatusChip(label: formatStatus(delivery.status), status: delivery.status),
                        if (delivery.lastLocationUpdateAt != null)
                              StatusChip(
                                label: 'Updated ${formatDateTime(delivery.lastLocationUpdateAt)}',
                              ),
                            if (delivery.receiverConfirmedAt != null)
                              const StatusChip(label: 'Receiver confirmed', status: 'APPROVED'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _workflow.map((String step) => _buildWorkflowStep(context, step, delivery.status)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionTitle(
                          title: 'Assignment Details',
                          subtitle: 'These details are visible to both receiver and donor.',
                        ),
                        const SizedBox(height: 12),
                        DetailRow(label: 'Order no.', value: delivery.orderNumber ?? 'Not set'),
                        DetailRow(label: 'Agent', value: delivery.agentName ?? 'Not set'),
                        DetailRow(label: 'Mobile', value: delivery.agentMobile ?? 'Not set'),
                        DetailRow(label: 'Vehicle', value: delivery.vehicleNumber ?? 'Not set'),
                        DetailRow(label: 'Pickup approved', value: formatDateTime(delivery.pickupApprovedAt)),
                        DetailRow(label: 'Delivered at', value: formatDateTime(delivery.deliveredAt)),
                        DetailRow(label: 'Receiver confirmed', value: formatDateTime(delivery.receiverConfirmedAt)),
                        DetailRow(
                          label: 'Last location',
                          value: delivery.lastLatitude == null || delivery.lastLongitude == null
                              ? 'No coordinate update yet'
                              : '${delivery.lastLatitude}, ${delivery.lastLongitude}',
                        ),
                        if (delivery.failedReason != null && delivery.failedReason!.isNotEmpty)
                          DetailRow(label: 'Failure', value: delivery.failedReason!),
                        if (delivery.notes != null && delivery.notes!.isNotEmpty)
                          DetailRow(label: 'Notes', value: delivery.notes!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    if (delivery.status == 'PICKUP_APPROVED')
                      ElevatedButton(
                        onPressed: () => _updateTransit(delivery, delivered: false),
                        child: const Text('Mark In Transit'),
                      ),
                    if (delivery.status == 'PICKUP_APPROVED' || delivery.status == 'IN_TRANSIT')
                      ElevatedButton(
                        onPressed: () => _updateTransit(delivery, delivered: true),
                        child: const Text('Mark Delivered'),
                      ),
                    if (delivery.status == 'DELIVERED' && delivery.receiverConfirmedAt == null)
                      ElevatedButton(
                        onPressed: () => _confirmReceipt(delivery),
                        child: const Text('Confirm Receipt'),
                      ),
                    if (delivery.status == 'ASSIGNED' || delivery.status == 'PICKUP_PENDING')
                      OutlinedButton(
                        onPressed: _openAssignment,
                        child: const Text('Edit Assignment'),
                      ),
                    if (delivery.status != 'DELIVERED' &&
                        delivery.status != 'FAILED' &&
                        delivery.status != 'CANCELLED')
                      OutlinedButton(
                        onPressed: () => _markFailed(delivery),
                        child: const Text('Mark Failed'),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TimelineScreen.claim(
                              claimId: widget.claim.id,
                              title: 'Claim Timeline',
                            ),
                          ),
                        );
                      },
                      child: const Text('View Timeline'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkflowStep(BuildContext context, String step, String currentStatus) {
    final bool completed = _stepIndex(step) <= _stepIndex(currentStatus);
    final bool current = step == currentStatus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFE7F7EE) : const Color(0xFFF6F1E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: current ? Theme.of(context).colorScheme.primary : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: completed ? const Color(0xFF0B6B2A) : const Color(0xFF9A6700),
          ),
          const SizedBox(width: 8),
          Text(
            formatStatus(step),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  int _stepIndex(String status) {
    final int index = _workflow.indexOf(status);
    return index == -1 ? 0 : index;
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'ASSIGNED':
      case 'PICKUP_PENDING':
        return 'Waiting for the donor to verify the assigned delivery agent.';
      case 'PICKUP_APPROVED':
        return 'Pickup is approved. The receiver organization can move the delivery into transit.';
      case 'IN_TRANSIT':
        return 'The assigned agent is on the way to complete the delivery.';
      case 'DELIVERED':
        return deliveryReceiptMessage;
      case 'FAILED':
        return 'Delivery failed. Review the recorded reason and claim timeline.';
      case 'CANCELLED':
        return 'Delivery was cancelled and is no longer active.';
      default:
        return 'Track donor approval, movement, and completion from here.';
    }
  }

  String get deliveryReceiptMessage => 'Delivery is complete. Record final receipt once the resource has been checked in.';

  Future<void> _openAssignment() async {
    final DeliveryTask? updatedDelivery = await Navigator.of(context).push<DeliveryTask>(
      MaterialPageRoute<DeliveryTask>(
        builder: (_) => AssignDeliveryScreen(claim: widget.claim),
      ),
    );
    if (updatedDelivery != null && mounted) {
      setState(() => _future = Future<DeliveryTask?>.value(updatedDelivery));
    } else if (mounted) {
      setState(() => _future = _load());
    }
  }

  Future<void> _updateTransit(DeliveryTask delivery, {required bool delivered}) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: delivered ? 'Confirm delivery completion' : 'Move delivery in transit',
      message: delivered
          ? 'This marks the delivery complete and finalizes the claim workflow.'
          : 'This updates the delivery status to in transit.',
      confirmLabel: delivered ? 'Mark delivered' : 'Mark in transit',
    );
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final DeliveryTask updated = delivered
          ? await DeliveryApi(auth.apiClient).delivered(auth.token!, claimId: delivery.claimId)
          : await DeliveryApi(auth.apiClient).inTransit(auth.token!, claimId: delivery.claimId);
      if (!mounted) return;
      AppFeedback.showSuccess(context, delivered ? 'Delivery marked completed' : 'Delivery marked in transit');
      setState(() => _future = Future<DeliveryTask?>.value(updated));
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }

  Future<void> _markFailed(DeliveryTask delivery) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final TextEditingController controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark Delivery Failed'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Failure reason'),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) {
      controller.dispose();
      return;
    }

    try {
      final DeliveryTask updated = await DeliveryApi(auth.apiClient).fail(
        auth.token!,
        claimId: delivery.claimId,
        failedReason: reason,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Delivery marked failed');
      setState(() => _future = Future<DeliveryTask?>.value(updated));
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmReceipt(DeliveryTask delivery) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Confirm final receipt',
      message: 'This records that the receiver organization has fully received the delivery.',
      confirmLabel: 'Confirm receipt',
    );
    if (!mounted || !confirmed) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final DeliveryTask updated = await DeliveryApi(auth.apiClient).confirmReceipt(
        auth.token!,
        claimId: delivery.claimId,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Final receipt confirmed');
      setState(() => _future = Future<DeliveryTask?>.value(updated));
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
