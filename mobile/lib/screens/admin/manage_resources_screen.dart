import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/admin_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/status_chip.dart';

class ManageResourcesScreen extends StatefulWidget {
  const ManageResourcesScreen({super.key});

  @override
  State<ManageResourcesScreen> createState() => _ManageResourcesScreenState();
}

class _ManageResourcesScreenState extends State<ManageResourcesScreen> {
  late Future<List<ResourceItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ResourceItem>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return AdminApi(auth.apiClient).resources(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Manage Resources',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<ResourceItem>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ResourceItem>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load resources',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.rule_folder_outlined,
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
          final List<ResourceItem> resources = snapshot.data!;
          if (resources.isEmpty) {
            return const EmptyStateCard(
              title: 'No resources found',
              message: 'Active and moderated listings will appear here for review.',
              icon: Icons.inventory_2_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              itemCount: resources.length + 1,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Card(
                    color: const Color(0xFFEAF7EF),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.info_outline_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Newest resources are shown first. Pull down to refresh after a donor creates a listing.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final ResourceItem resource = resources[index - 1];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(resource.title, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            if (index == 1) const StatusChip(label: 'Newest', status: 'APPROVED'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            StatusChip(label: resource.resourceType, status: resource.resourceType),
                            StatusChip(label: formatStatus(resource.status), status: resource.status),
                            if (resource.resourceType == 'MEDICINE')
                              StatusChip(
                                label: formatStatus(resource.medicalVerificationStatus),
                                status: resource.medicalVerificationStatus,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Donor: ${resource.donorName}'),
                        Text('Location: ${resource.city}, ${resource.area}'),
                        if (resource.createdAt != null) Text('Created: ${formatDateTime(resource.createdAt)}'),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _remove(resource.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Remove'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _remove(String resourceId) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Remove resource',
      message: 'This moderates the listing and removes it from active discovery. Continue?',
      confirmLabel: 'Remove',
    );
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await AdminApi(auth.apiClient).removeResource(auth.token!, resourceId);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Resource removed');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
