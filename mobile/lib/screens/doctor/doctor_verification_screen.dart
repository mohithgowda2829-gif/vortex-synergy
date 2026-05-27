import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/dashboard_api.dart';
import '../../api/medical_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/role_dashboard_summary.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/hero_header_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/verification_banner.dart';

class DoctorVerificationScreen extends StatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  State<DoctorVerificationScreen> createState() => _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  late Future<List<ResourceItem>> _future;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ResourceItem>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    final MedicalApi api = MedicalApi(auth.apiClient);
    return _showHistory ? api.history(auth.token!) : api.pending(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool approved = auth.user?.adminApproved ?? false;
    final DashboardApi dashboardApi = DashboardApi(auth.apiClient);

    return AppScaffold(
      title: 'Medical Verification',
      onLogout: () => auth.logout(),
      child: ListView(
        children: <Widget>[
          const HeroHeaderCard(
            eyebrow: 'Medical compliance',
            title: 'Verify medicine before it reaches receivers',
            subtitle:
                'Review seal status, expiry, category, access type, and notes so only safe medicine becomes claimable.',
            icon: Icons.medical_services_outlined,
            chips: <String>['Sealed only', 'Expiry checks', 'Verifier notes'],
            accent: Color(0xFFD66B1F),
          ),
          const SizedBox(height: 16),
          FutureBuilder<RoleDashboardSummary>(
            future: dashboardApi.roleSummary(auth.token!),
            builder: (BuildContext context, AsyncSnapshot<RoleDashboardSummary> snapshot) {
              final RoleDashboardSummary? summary = snapshot.data;
              if (summary == null) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ResponsiveMetricGrid(
                  maxColumns: 2,
                  children: <Widget>[
                    MetricCard(
                      label: 'Pending verifications',
                      value: summary.pendingVerificationCount.toString(),
                      icon: Icons.pending_actions_outlined,
                      highlight: true,
                    ),
                    MetricCard(
                      label: 'Approved reviews',
                      value: summary.approvedVerificationCount.toString(),
                      icon: Icons.task_alt_outlined,
                    ),
                    MetricCard(
                      label: 'Rejected reviews',
                      value: summary.rejectedVerificationCount.toString(),
                      icon: Icons.cancel_outlined,
                    ),
                    MetricCard(
                      label: 'Unread alerts',
                      value: summary.unreadNotifications.toString(),
                      icon: Icons.notifications_active_outlined,
                    ),
                  ],
                ),
              );
            },
          ),
          const VerificationBanner(
            message:
                'Doctor and pharmacist accounts need both placeholder contact verification and admin approval before medicine review becomes active.',
          ),
          if (!approved)
            Card(
              color: const Color(0xFFFFF2F0),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.pending_actions_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your medical reviewer account is still pending admin approval. You can log in, but approvals should wait until the admin verifies your role.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: SectionTitle(
              title: 'Medicine Reviews',
              subtitle: 'Approve pending listings or inspect your completed review history.',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text('Pending')),
                ButtonSegment<bool>(value: true, label: Text('History')),
              ],
              selected: <bool>{_showHistory},
              showSelectedIcon: false,
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _showHistory = selection.first;
                  _future = _load();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ResourceItem>>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<List<ResourceItem>> snapshot) {
              if (snapshot.hasError) {
                return EmptyStateCard(
                  title: 'Unable to load medicine reviews',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.medication_liquid_outlined,
                  action: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Retry'),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final List<ResourceItem> resources = snapshot.data!;
              if (resources.isEmpty) {
                return EmptyStateCard(
                  title: _showHistory ? 'No completed reviews yet' : 'No pending medicine listings',
                  message: _showHistory
                      ? 'Approved and rejected medicine reviews will appear here after you make decisions.'
                      : 'Approved and rejected reviews will still remain visible in notifications and audit timelines.',
                  icon: Icons.task_alt_outlined,
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resources.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final ResourceItem resource = resources[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(resource.title, style: Theme.of(context).textTheme.titleMedium),
                              ),
                              StatusChip(
                                label: formatStatus(resource.medicalVerificationStatus),
                                status: resource.medicalVerificationStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DetailRow(label: 'Medicine', value: resource.medicineName ?? 'Not set'),
                          DetailRow(label: 'Batch', value: resource.batchNumber ?? 'Not set'),
                          DetailRow(label: 'Category', value: resource.medicineCategory ?? 'Not set'),
                          DetailRow(label: 'Access', value: resource.medicineAccessType ?? 'Not set'),
                          DetailRow(
                            label: 'Prescription',
                            value: (resource.prescriptionRequired ?? false) ? 'Required' : 'Not required',
                          ),
                          DetailRow(label: 'Seal', value: resource.medicineSealStatus ?? 'Unknown'),
                          DetailRow(label: 'Expiry', value: formatDate(resource.medicineExpiryDate)),
                          DetailRow(label: 'Donor', value: resource.donorName),
                          if (resource.verificationNotes != null && resource.verificationNotes!.isNotEmpty)
                            DetailRow(label: 'Existing notes', value: resource.verificationNotes!),
                          const SizedBox(height: 12),
                          if (!_showHistory)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                ElevatedButton(
                                  onPressed: approved ? () => _decide(resource.id, true) : null,
                                  child: const Text('Approve'),
                                ),
                                OutlinedButton(
                                  onPressed: approved ? () => _decide(resource.id, false) : null,
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _decide(String resourceId, bool approved) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final TextEditingController noteController = TextEditingController(
      text: approved ? 'Sealed and safe for distribution' : 'Rejected during medical review',
    );
    final TextEditingController verificationNotesController = TextEditingController(
      text: approved ? 'Approved with compliance review notes' : 'Rejected with compliance concerns recorded',
    );

    final ({String note, String verificationNotes})? result = await showDialog<({String note, String verificationNotes})>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(approved ? 'Approve medicine listing' : 'Reject medicine listing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Decision note'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: verificationNotesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Compliance / verification notes'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop((
                note: noteController.text.trim(),
                verificationNotes: verificationNotesController.text.trim(),
              )),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      noteController.dispose();
      verificationNotesController.dispose();
      return;
    }

    try {
      if (approved) {
        await MedicalApi(auth.apiClient).verify(
          auth.token!,
          resourceId: resourceId,
          note: result.note,
          verificationNotes: result.verificationNotes,
        );
      } else {
        await MedicalApi(auth.apiClient).reject(
          auth.token!,
          resourceId: resourceId,
          note: result.note,
          verificationNotes: result.verificationNotes,
        );
      }
      if (!mounted) return;
      AppFeedback.showSuccess(context, approved ? 'Medicine approved' : 'Medicine rejected');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      noteController.dispose();
      verificationNotesController.dispose();
    }
  }
}
