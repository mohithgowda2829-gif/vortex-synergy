import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/dashboard_api.dart';
import '../../models/role_dashboard_summary.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/hero_header_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/section_title.dart';
import '../../widgets/verification_banner.dart';
import '../common/report_center_screen.dart';
import 'browse_resources_screen.dart';
import 'my_claims_screen.dart';

class ReceiverDashboardScreen extends StatefulWidget {
  const ReceiverDashboardScreen({super.key});

  @override
  State<ReceiverDashboardScreen> createState() => _ReceiverDashboardScreenState();
}

class _ReceiverDashboardScreenState extends State<ReceiverDashboardScreen> {
  Future<RoleDashboardSummary>? _summaryFuture;
  String? _activeToken;

  @override
  void initState() {
    super.initState();
    _refreshFuture();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshFuture();
  }

  void _refreshFuture() {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? token = auth.token;
    if (token == null || token == _activeToken) {
      return;
    }
    _activeToken = token;
    _summaryFuture = DashboardApi(auth.apiClient).roleSummary(token);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Receiver Dashboard',
      onLogout: () => context.read<AuthProvider>().logout(),
      child: ListView(
        children: <Widget>[
          const HeroHeaderCard(
            eyebrow: 'Receiver workspace',
            title: 'Find verified support faster',
            subtitle:
                'Browse available food and medicine, claim fairly, and assign your own pickup agent when self-pickup is not practical.',
            icon: Icons.diversity_3_outlined,
            chips: <String>['Search resources', 'Assign pickup', 'Track delivery'],
            accent: Color(0xFF155E75),
          ),
          const SizedBox(height: 16),
          FutureBuilder<RoleDashboardSummary>(
            future: _summaryFuture,
            builder: (BuildContext context, AsyncSnapshot<RoleDashboardSummary> snapshot) {
              final RoleDashboardSummary? summary = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle(
                    title: 'Operational Snapshot',
                    subtitle: 'See live claims, deliveries, and urgent work before taking action.',
                  ),
                  const SizedBox(height: 12),
                  if (summary == null)
                    const LinearProgressIndicator()
                  else
                    ResponsiveMetricGrid(
                      maxColumns: 2,
                      children: <Widget>[
                        MetricCard(
                          label: 'Active claims',
                          value: summary.activeClaims.toString(),
                          icon: Icons.assignment_turned_in_outlined,
                          highlight: true,
                        ),
                        MetricCard(
                          label: 'Completed claims',
                          value: summary.completedClaims.toString(),
                          icon: Icons.fact_check_outlined,
                        ),
                        MetricCard(
                          label: 'Active deliveries',
                          value: summary.activeDeliveryCount.toString(),
                          icon: Icons.local_shipping_outlined,
                        ),
                        MetricCard(
                          label: 'Urgent claims',
                          value: summary.urgentClaimCount.toString(),
                          icon: Icons.priority_high_rounded,
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const VerificationBanner(
            message:
                'Complete the placeholder checks so your reservations and pickup confirmations stay attached to a verified account.',
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFFFFF7E7),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.balance_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fair-access policy: no fixed daily claim cap. Duplicate active reservations on the same listing are blocked, and frequent recent claims lower priority for the next request.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DashboardActionCard(
            title: 'Browse Resources',
            subtitle: 'Filter food and medicine by type, city, area, and expiry.',
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BrowseResourcesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'My Claims',
            subtitle: 'Track reservations, pickup codes, delivery assignments, and progress.',
            icon: Icons.assignment_turned_in_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyClaimsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Reports',
            subtitle: 'Preview CSV operational summaries for claims, expiry, medicine, and deliveries.',
            icon: Icons.table_chart_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportCenterScreen(title: 'Receiver Reports'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
