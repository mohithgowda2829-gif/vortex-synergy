import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/claim_api.dart';
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

class HandoverConfirmationScreen extends StatefulWidget {
  const HandoverConfirmationScreen({super.key});

  @override
  State<HandoverConfirmationScreen> createState() => _HandoverConfirmationScreenState();
}

class _HandoverConfirmationScreenState extends State<HandoverConfirmationScreen> {
  late Future<_DonorPickupData> _future;
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _deliveryCodeControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    for (final TextEditingController controller in _deliveryCodeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_DonorPickupData> _load() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final ClaimApi claimApi = ClaimApi(auth.apiClient);
    final DeliveryApi deliveryApi = DeliveryApi(auth.apiClient);
    final List<ClaimItem> claims = await claimApi.donor(auth.token!);
    final List<DeliveryTask> deliveries = await deliveryApi.donor(auth.token!);
    return _DonorPickupData(claims: claims, deliveries: deliveries);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Pickup Approval Queue',
      onLogout: () => auth.logout(),
      child: FutureBuilder<_DonorPickupData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_DonorPickupData> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load pickup queue',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.verified_user_outlined,
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

          final _DonorPickupData data = snapshot.data!;
          final List<ClaimItem> selfPickupClaims =
              data.claims.where((ClaimItem claim) => claim.status == 'RESERVED' && !claim.deliveryRequested).toList();
          final List<DeliveryTask> activeDeliveries = data.deliveries
              .where((DeliveryTask delivery) =>
                  delivery.status != 'DELIVERED' && delivery.status != 'FAILED' && delivery.status != 'CANCELLED')
              .toList();

          if (selfPickupClaims.isEmpty && activeDeliveries.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => setState(() => _future = _load()),
              child: ListView(
                children: const <Widget>[
                  EmptyStateCard(
                    title: 'No active pickup approvals',
                    message: 'Assigned deliveries and self-pickup handovers will appear here when donor action is required.',
                    icon: Icons.verified_user_outlined,
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
                    child: const SectionTitle(
                      title: 'Pickup Verification Queue',
                      subtitle: 'Review receiver-assigned delivery agents and complete self-pickup handovers with the correct claim code.',
                    ),
                  ),
                ),
                if (activeDeliveries.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  const SectionTitle(
                    title: 'Assigned Deliveries',
                    subtitle: 'Approve pickup only after the delivery agent details match the arriving team.',
                  ),
                  const SizedBox(height: 12),
                  ...activeDeliveries.map(_buildDeliveryCard),
                ],
                if (selfPickupClaims.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  const SectionTitle(
                    title: 'Self Pickup Handover',
                    subtitle: 'Use the receiver claim code to confirm direct handover securely.',
                  ),
                  const SizedBox(height: 12),
                  ...selfPickupClaims.map(_buildSelfPickupCard),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryTask delivery) {
    final bool pickupPendingApproval = delivery.status == 'ASSIGNED' || delivery.status == 'PICKUP_PENDING';
    final TextEditingController codeController =
        _deliveryCodeControllers.putIfAbsent(delivery.claimId, TextEditingController.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(delivery.resourceTitle, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  StatusChip(label: formatStatus(delivery.status), status: delivery.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (delivery.pickupApprovedAt != null)
                    const StatusChip(label: 'Pickup approved', status: 'APPROVED'),
                  if (delivery.receiverConfirmedAt != null)
                    const StatusChip(label: 'Receiver confirmed', status: 'APPROVED'),
                ],
              ),
              const SizedBox(height: 12),
              DetailRow(label: 'Receiver', value: delivery.receiverName),
              DetailRow(label: 'Order no.', value: delivery.orderNumber ?? 'Not set'),
              DetailRow(label: 'Agent', value: delivery.agentName ?? 'Not set'),
              DetailRow(label: 'Mobile', value: delivery.agentMobile ?? 'Not set'),
              DetailRow(label: 'Vehicle', value: delivery.vehicleNumber ?? 'Not set'),
              if (delivery.notes != null && delivery.notes!.isNotEmpty) DetailRow(label: 'Notes', value: delivery.notes!),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Enter receiver pickup code',
                  helperText: 'Ask the receiver/agent to show the pickup code before approving handover.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: pickupPendingApproval
                        ? () => _approvePickup(delivery, codeController.text.trim())
                        : null,
                    child: Text(pickupPendingApproval ? 'Approve Pickup' : 'Already Approved'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TimelineScreen.claim(
                            claimId: delivery.claimId,
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
        ),
      ),
    );
  }

  Widget _buildSelfPickupCard(ClaimItem claim) {
    final TextEditingController controller = _controllers.putIfAbsent(claim.id, TextEditingController.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(claim.resourceTitle, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  StatusChip(label: formatStatus(claim.status), status: claim.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  const StatusChip(label: 'Self pickup', status: 'APPROVED'),
                  if (claim.pickupConfirmedByReceiver)
                    const StatusChip(label: 'Receiver confirmed', status: 'APPROVED'),
                ],
              ),
              const SizedBox(height: 12),
              Text('Receiver: ${claim.receiverName}'),
              Text('Quantity: ${claim.quantity}'),
              Text('Reserved: ${formatDateTime(claim.reservedAt)}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Enter receiver pickup code'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _completeHandover(claim, controller.text.trim()),
                    child: const Text('Confirm Self Pickup'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TimelineScreen.claim(
                            claimId: claim.id,
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
        ),
      ),
    );
  }

  Future<void> _approvePickup(DeliveryTask delivery, String pickupCode) async {
    if (pickupCode.isEmpty) {
      AppFeedback.showError(context, 'Receiver pickup code is required');
      return;
    }

    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Approve pickup',
      message:
          'Approve ${delivery.agentName ?? 'the assigned agent'} for order ${delivery.orderNumber ?? 'this delivery'} after verifying the receiver pickup code?',
      confirmLabel: 'Approve pickup',
    );
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await DeliveryApi(
        auth.apiClient,
      ).pickupApprove(auth.token!, claimId: delivery.claimId, pickupCode: pickupCode);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Pickup approved for assigned delivery');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }

  Future<void> _completeHandover(ClaimItem claim, String pickupCode) async {
    if (pickupCode.isEmpty) {
      AppFeedback.showError(context, 'Pickup code is required');
      return;
    }

    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Complete self pickup',
      message: 'This will finalize the handover for ${claim.resourceTitle}. Continue?',
      confirmLabel: 'Complete handover',
    );
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await ClaimApi(auth.apiClient).handover(auth.token!, claim.id, pickupCode);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Self pickup handover completed');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}

class _DonorPickupData {
  const _DonorPickupData({required this.claims, required this.deliveries});

  final List<ClaimItem> claims;
  final List<DeliveryTask> deliveries;
}
