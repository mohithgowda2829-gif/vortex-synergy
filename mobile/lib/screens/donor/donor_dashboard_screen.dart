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
import 'add_resource_screen.dart';
import 'donor_certificate_screen.dart';
import 'handover_confirmation_screen.dart';
import 'my_donations_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  Future<RoleDashboardSummary>? _summaryFuture;
  Future<DonorCertificate>? _certificateFuture;
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
    final DashboardApi dashboardApi = DashboardApi(auth.apiClient);
    _activeToken = token;
    _summaryFuture = dashboardApi.roleSummary(token);
    _certificateFuture = dashboardApi.donorCertificate(token);
  }

  @override
  Widget build(BuildContext context) {
    final String donorName = context.select<AuthProvider, String>(
      (AuthProvider auth) => auth.user?.fullName ?? 'Donor',
    );

    return AppScaffold(
      title: 'Donor Dashboard',
      onLogout: () => context.read<AuthProvider>().logout(),
      child: ListView(
        children: <Widget>[
          HeroHeaderCard(
            eyebrow: 'Donor command center',
            title: 'Welcome, $donorName',
            subtitle: 'List safe food and sealed medicine, monitor impact, and approve handovers with traceable records.',
            icon: Icons.inventory_2_outlined,
            chips: const <String>['Food safety', 'Medicine compliance', 'Pickup approval'],
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
                    title: 'Donation Snapshot',
                    subtitle: 'Track what is active, completed, expired, and waiting for delivery progress.',
                  ),
                  const SizedBox(height: 12),
                  if (summary == null)
                    const LinearProgressIndicator()
                  else
                    ResponsiveMetricGrid(
                      maxColumns: 2,
                      children: <Widget>[
                        MetricCard(
                          label: 'Active donations',
                          value: summary.activeDonations.toString(),
                          icon: Icons.inventory_2_outlined,
                          highlight: true,
                        ),
                        MetricCard(
                          label: 'Claimed donations',
                          value: summary.claimedDonations.toString(),
                          icon: Icons.task_alt_outlined,
                        ),
                        MetricCard(
                          label: 'Expired donations',
                          value: summary.expiredDonations.toString(),
                          icon: Icons.hourglass_disabled_outlined,
                        ),
                        MetricCard(
                          label: 'Assigned deliveries',
                          value: summary.assignedDeliveryCount.toString(),
                          icon: Icons.local_shipping_outlined,
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
                'Food donations require a verified donor account. Complete both placeholder verifications before adding public listings.',
          ),
          const SizedBox(height: 16),
          FutureBuilder<DonorCertificate>(
            future: _certificateFuture,
            builder: (BuildContext context, AsyncSnapshot<DonorCertificate> snapshot) {
              final DonorCertificate? certificate = snapshot.data;
              return Card(
                color: const Color(0xFFE6F7F0),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Donor Certificate', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (certificate == null)
                        const LinearProgressIndicator()
                      else
                        Text(
                          '${certificate.donorName} has completed ${certificate.numberOfContributions} verified contribution(s) with an impact count of ${certificate.impactCount}.',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          DashboardActionCard(
            title: 'Add Resource',
            subtitle: 'Create a food or medicine listing with safety details.',
            icon: Icons.add_box_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddResourceScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Certificate Details',
            subtitle: 'Open the full donor certificate view and download it as a shareable HTML file.',
            icon: Icons.workspace_premium_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DonorCertificateScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'My Donations',
            subtitle: 'Review active, pending, claimed, and expired donations.',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyDonationsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardActionCard(
            title: 'Handover Confirmation',
            subtitle: 'Approve assigned receiver delivery pickups and complete self-pickup handovers.',
            icon: Icons.verified_user_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HandoverConfirmationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
