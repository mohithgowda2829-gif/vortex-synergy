import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/admin_api.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/responsive_metric_grid.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Analytics',
      onLogout: () => auth.logout(),
      child: FutureBuilder<DashboardSummary>(
        future: AdminApi(auth.apiClient).analytics(auth.token!),
        builder: (BuildContext context, AsyncSnapshot<DashboardSummary> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final DashboardSummary data = snapshot.data!;
          return ResponsiveMetricGrid(
            maxColumns: 2,
            children: <Widget>[
              _MetricCard(label: 'Meals Saved', value: data.totalMealsSaved.toString()),
              _MetricCard(label: 'Medicine Kits', value: data.medicineKitsDistributed.toString()),
              _MetricCard(label: 'Donors', value: data.donorCount.toString()),
              _MetricCard(label: 'Completed Claims', value: data.completedClaims.toString()),
              _MetricCard(
                label: 'Expired Resources Prevented',
                value: data.expiredResourcesPreventedFromMisuse.toString(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
