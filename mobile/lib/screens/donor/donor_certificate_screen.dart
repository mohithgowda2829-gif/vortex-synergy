import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/dashboard_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../providers/auth_provider.dart';
import '../../utils/file_download.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/section_title.dart';

class DonorCertificateScreen extends StatefulWidget {
  const DonorCertificateScreen({super.key});

  @override
  State<DonorCertificateScreen> createState() => _DonorCertificateScreenState();
}

class _DonorCertificateScreenState extends State<DonorCertificateScreen> {
  late Future<DonorCertificateDetail> _future;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DonorCertificateDetail> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return DashboardApi(auth.apiClient).donorCertificateDetail(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Donor Certificate',
      onLogout: () => auth.logout(),
      child: FutureBuilder<DonorCertificateDetail>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<DonorCertificateDetail> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load certificate',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.workspace_premium_outlined,
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

          final DonorCertificateDetail certificate = snapshot.data!;
          return ListView(
            children: <Widget>[
              Card(
                color: const Color(0xFFF7F1E4),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        certificate.programName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contribution Certificate',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        certificate.donorName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        certificate.statement,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ResponsiveMetricGrid(
                maxColumns: 2,
                children: <Widget>[
                  MetricCard(
                    label: 'Contributions',
                    value: certificate.numberOfContributions.toString(),
                    icon: Icons.inventory_2_outlined,
                    highlight: true,
                  ),
                  MetricCard(
                    label: 'Impact count',
                    value: certificate.impactCount.toString(),
                    icon: Icons.favorite_border_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionTitle(
                        title: 'Certificate Details',
                        subtitle: 'Use these details for demos, printouts, or formal project submission.',
                      ),
                      const SizedBox(height: 12),
                      DetailRow(label: 'Certificate no.', value: certificate.certificateNumber),
                      DetailRow(label: 'Issued at', value: formatDateTime(certificate.issuedAt)),
                      DetailRow(label: 'Issued by', value: certificate.issuedBy),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : () => _downloadCertificate(certificate),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(_downloading ? 'Downloading...' : 'Download Certificate'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadCertificate(DonorCertificateDetail certificate) async {
    setState(() => _downloading = true);
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final String html = await DashboardApi(auth.apiClient).donorCertificateDownload(auth.token!);
      final bool saved = await saveTextDownload(
        suggestedName: 'donor-certificate-${certificate.certificateNumber.toLowerCase()}.html',
        mimeType: 'text/html',
        content: html,
      );
      if (!mounted) {
        return;
      }
      if (saved) {
        AppFeedback.showSuccess(context, 'Certificate download started.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }
}
