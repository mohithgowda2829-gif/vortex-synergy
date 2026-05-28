import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/admin_api.dart';
import '../../api/dashboard_api.dart';
import '../../models/dashboard_summary.dart';
import '../../models/role_dashboard_summary.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dashboard_action_card.dart';
import '../../widgets/hero_header_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/section_title.dart';
import '../common/report_center_screen.dart';
import 'analytics_screen.dart';
import 'manage_resources_screen.dart';
import 'operational_monitoring_screen.dart';
import 'verify_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<DashboardSummary>? _analyticsFuture;
  Future<RoleDashboardSummary>? _summaryFuture;
  String? _activeToken;

  @override
  void initState() {
    super.initState();
    _refreshFutures();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshFutures();
  }

  void _refreshFutures() {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? token = auth.token;
    if (token == null || token == _activeToken) {
      return;
    }
    final AdminApi adminApi = AdminApi(auth.apiClient);
    final DashboardApi dashboardApi = DashboardApi(auth.apiClient);
    _activeToken = token;
    _analyticsFuture = adminApi.analytics(token);
    _summaryFuture = dashboardApi.roleSummary(token);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admin Dashboard',
      onLogout: () => context.read<AuthProvider>().logout(),
      child: ListView(
        children: <Widget>[
          const HeroHeaderCard(
            eyebrow: 'Admin operations',
            title: 'Monitor trust, safety, and impact',
            subtitle:
                'Review approvals, moderate resources, inspect delivery activity, and export reports from one operational control surface.',
            icon: Icons.admin_panel_settings_outlined,
            chips: <String>['User verification', 'Moderation', 'Reports'],
            accent: Color(0xFF132D2B),
          ),
          const SizedBox(height: 16),
          FutureBuilder<DashboardSummary>(
            future: _analyticsFuture,
            builder: (BuildContext context, AsyncSnapshot<DashboardSummary> snapshot) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Platform Overview', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (!snapshot.hasData)
                        const LinearProgressIndicator()
                      else ...<Widget>[
                        Text('Meals saved: ${snapshot.data!.totalMealsSaved}'),
                        Text('Medicine kits distributed: ${snapshot.data!.medicineKitsDistributed}'),
                        Text('Completed claims: ${snapshot.data!.completedClaims}'),
                      ],
                    ],
                  ),
                ),
              );
            },
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
                    title: 'Admin Snapshot',
                    subtitle: 'Pending approvals, moderated listings, and live system activity.',
                  ),
                  const SizedBox(height: 12),
                  if (summary == null)
                    const LinearProgressIndicator()
                  else
                    ResponsiveMetricGrid(
                      maxColumns: 2,
                      children: <Widget>[
                        MetricCard(
                          label: 'Pending approvals',
                          value: summary.pendingUserApprovalCount.toString(),
                          icon: Icons.verified_outlined,
                          highlight: true,
                        ),
                        MetricCard(
                          label: 'Moderated resources',
                          value: summary.moderatedResourceCount.toString(),
                          icon: Icons.gpp_maybe_outlined,
                        ),
                        MetricCard(
                          label: 'Active deliveries',
                          value: summary.activeSystemDeliveryCount.toString(),
                          icon: Icons.local_shipping_outlined,
                        ),
                        MetricCard(
                          label: 'Unread alerts',
                          value: summary.unreadNotifications.toString(),
                          icon: Icons.notifications_active_outlined,
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          DashboardActionCard(
            title: 'Verify Users',
            subtitle: 'Approve doctor and pharmacist accounts and donor medicine flow.',
            icon: Icons.verified_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const VerifyUsersScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Manage Resources',
            subtitle: 'Moderate invalid listings and remove unsafe resources.',
            icon: Icons.rule_folder_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ManageResourcesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Analytics',
            subtitle: 'See platform-wide impact metrics and misuse prevention counts.',
            icon: Icons.insights_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Operational Monitoring',
            subtitle: 'Track active delivery progress and operational state changes.',
            icon: Icons.local_shipping_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OperationalMonitoringScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Reports',
            subtitle: 'Preview CSV exports for donations, claims, expiry, medicine, and deliveries.',
            icon: Icons.table_chart_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportCenterScreen(title: 'Admin Reports'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
