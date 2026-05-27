import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/claim_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/claim_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/status_chip.dart';
import '../common/timeline_screen.dart';
import 'delivery_tracking_screen.dart';

class ConfirmPickupScreen extends StatefulWidget {
  const ConfirmPickupScreen({super.key, required this.claim});

  final ClaimItem claim;

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  late ClaimItem _claim;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _claim = widget.claim;
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Confirm Pickup',
      onLogout: () => auth.logout(),
      child: ListView(
        children: <Widget>[
          Card(
            color: const Color(0xFFE7FAF5),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Show this code at pickup', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SelectableText(
                    _claim.pickupCode ?? 'Unavailable',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
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
                  DetailRow(label: 'Resource', value: _claim.resourceTitle),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      StatusChip(label: formatStatus(_claim.status), status: _claim.status),
                      StatusChip(
                        label: _claim.deliveryRequested ? 'Receiver delivery' : 'Self pickup',
                        status: _claim.deliveryRequested ? 'PENDING' : 'APPROVED',
                      ),
                      if (_claim.pickupConfirmedByReceiver)
                        const StatusChip(label: 'Confirmed', status: 'APPROVED'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DetailRow(label: 'Reserved At', value: formatDateTime(_claim.reservedAt)),
                  DetailRow(label: 'Expires At', value: formatDateTime(_claim.reservationExpiresAt)),
                  if (_claim.priorityScore != null)
                    DetailRow(label: 'Priority score', value: _claim.priorityScore.toString()),
                  if (_claim.priorityExplanation != null && _claim.priorityExplanation!.isNotEmpty)
                    DetailRow(label: 'Priority rule', value: _claim.priorityExplanation!),
                  const DetailRow(
                    label: 'Fair access policy',
                    value:
                        'No fixed daily cap is applied. Repeated recent claims can lower priority, and the same listing cannot be reserved twice at once.',
                  ),
                  if (_claim.deliveryRequested) ...<Widget>[
                    const Divider(height: 28),
                    const Text(
                      'This claim uses receiver-managed delivery. Confirm the reservation and then assign an agent from the delivery tracking flow.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _working ? null : _openDeliveryTracking,
                        child: const Text('Open Delivery Tracking'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TimelineScreen.claim(
                              claimId: _claim.id,
                              title: 'Claim Timeline',
                            ),
                          ),
                        );
                      },
                      child: const Text('View Timeline'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_working || _claim.pickupConfirmedByReceiver) ? null : _confirmReservation,
              child: Text(
                _claim.pickupConfirmedByReceiver
                    ? 'Reservation Already Confirmed'
                    : _working
                        ? 'Confirming...'
                        : 'Confirm Reservation',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReservation() async {
    setState(() => _working = true);
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      _claim = await ClaimApi(auth.apiClient).confirm(auth.token!, _claim.id);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Reservation confirmed. Show your pickup code at handover.');
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openDeliveryTracking() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliveryTrackingScreen(claim: _claim),
      ),
    );
  }
}
