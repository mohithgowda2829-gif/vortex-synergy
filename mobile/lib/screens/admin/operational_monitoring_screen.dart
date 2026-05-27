import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/delivery_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/delivery_task.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/status_chip.dart';

class OperationalMonitoringScreen extends StatefulWidget {
  const OperationalMonitoringScreen({super.key});

  @override
  State<OperationalMonitoringScreen> createState() => _OperationalMonitoringScreenState();
}

class _OperationalMonitoringScreenState extends State<OperationalMonitoringScreen> {
  late Future<List<DeliveryTask>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DeliveryTask>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return DeliveryApi(auth.apiClient).receiver(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Operational Monitoring',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<DeliveryTask>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<DeliveryTask>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load delivery operations',
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
          final List<DeliveryTask> deliveries = snapshot.data!;
          if (deliveries.isEmpty) {
            return const EmptyStateCard(
              title: 'No delivery operations yet',
              message: 'Assigned deliveries will appear here for operational monitoring and audit review.',
              icon: Icons.local_shipping_outlined,
            );
          }
          return ListView.separated(
            itemCount: deliveries.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final DeliveryTask delivery = deliveries[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(delivery.resourceTitle),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        StatusChip(label: formatStatus(delivery.status), status: delivery.status),
                        const SizedBox(height: 8),
                        Text(
                          'Receiver: ${delivery.receiverName}\n'
                          'Agent: ${delivery.agentName ?? 'Not assigned'}\n'
                          'Updated: ${formatDateTime(delivery.lastLocationUpdateAt ?? delivery.deliveredAt)}',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
