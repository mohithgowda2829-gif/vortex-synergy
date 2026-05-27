import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/claim_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/claim_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';
import '../common/timeline_screen.dart';
import 'confirm_pickup_screen.dart';
import 'delivery_tracking_screen.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  late Future<List<ClaimItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ClaimItem>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return ClaimApi(auth.apiClient).mine(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'My Claims',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<ClaimItem>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ClaimItem>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load claims',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.assignment_late_outlined,
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

          final List<ClaimItem> claims = snapshot.data!;
          if (claims.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => setState(() => _future = _load()),
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 56),
                  EmptyStateCard(
                    title: 'No claims yet',
                    message: 'Claimed resources will appear here with pickup, delivery, and timeline actions.',
                    icon: Icons.assignment_late_outlined,
                  ),
                ],
              ),
            );
          }

          final int activeClaims = claims.where((ClaimItem claim) => claim.status == 'RESERVED').length;
          final int completedClaims = claims.where((ClaimItem claim) => claim.status == 'CLAIMED').length;
          final int deliveryClaims = claims.where((ClaimItem claim) => claim.deliveryRequested).length;
          final int urgentClaims = claims.where((ClaimItem claim) => (claim.priorityScore ?? 0) >= 70).length;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: const SectionTitle(
                      title: 'Claim Operations',
                      subtitle:
                          'Track confirmations, delivery handoffs, expiry pressure, audit history, and the current fair-access policy from one place.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ResponsiveMetricGrid(
                  maxColumns: 2,
                  children: <Widget>[
                    MetricCard(
                      label: 'Active claims',
                      value: activeClaims.toString(),
                      icon: Icons.assignment_turned_in_outlined,
                      highlight: true,
                    ),
                    MetricCard(
                      label: 'Completed claims',
                      value: completedClaims.toString(),
                      icon: Icons.task_alt_outlined,
                    ),
                    MetricCard(
                      label: 'Delivery claims',
                      value: deliveryClaims.toString(),
                      icon: Icons.local_shipping_outlined,
                    ),
                    MetricCard(
                      label: 'Urgent claims',
                      value: urgentClaims.toString(),
                      icon: Icons.priority_high_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...claims.map(
                  (ClaimItem claim) => Padding(
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
                                StatusChip(
                                  label: claim.deliveryRequested ? 'Receiver delivery' : 'Self pickup',
                                  status: claim.deliveryRequested ? 'PENDING' : 'APPROVED',
                                ),
                                if (claim.pickupConfirmedByReceiver)
                                  const StatusChip(label: 'Confirmed', status: 'APPROVED'),
                                if (claim.handoverConfirmed)
                                  const StatusChip(label: 'Completed', status: 'CLAIMED'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Reserved: ${formatDateTime(claim.reservedAt)}'),
                            Text('Reservation expires: ${formatDateTime(claim.reservationExpiresAt)}'),
                            if (claim.claimedAt != null) Text('Claim completed: ${formatDateTime(claim.claimedAt)}'),
                            if (claim.pickupCode != null) Text('Pickup code: ${claim.pickupCode}'),
                            if (claim.priorityScore != null)
                              Text(
                                'Priority: ${claim.priorityScore} (${claim.priorityExplanation ?? 'standard'})',
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                if (claim.status == 'RESERVED')
                                  OutlinedButton(
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ConfirmPickupScreen(claim: claim),
                                        ),
                                      );
                                      if (!mounted) return;
                                      setState(() => _future = _load());
                                    },
                                    child: Text(
                                      claim.pickupConfirmedByReceiver ? 'View Pickup' : 'Confirm Pickup',
                                    ),
                                  ),
                                if (claim.status == 'RESERVED' && claim.deliveryRequested)
                                  OutlinedButton(
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => DeliveryTrackingScreen(claim: claim),
                                        ),
                                      );
                                      if (!mounted) return;
                                      setState(() => _future = _load());
                                    },
                                    child: const Text('Track Delivery'),
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
                                  child: const Text('Timeline'),
                                ),
                                if (claim.status == 'RESERVED' && !claim.handoverConfirmed)
                                  TextButton(
                                    onPressed: () => _cancel(claim.id),
                                    child: const Text('Cancel'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(String claimId) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Cancel claim',
      message: 'This releases the reservation and updates the audit history. Continue?',
      confirmLabel: 'Cancel claim',
    );
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await ClaimApi(auth.apiClient).cancel(auth.token!, claimId, reason: 'Cancelled by receiver');
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Claim cancelled');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
