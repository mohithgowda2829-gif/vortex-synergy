import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/resource_api.dart';
import '../../config/app_config.dart';
import '../../config/app_formatters.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import 'donation_details_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  late Future<List<ResourceItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ResourceItem>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return ResourceApi(auth.apiClient).mine(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'My Donations',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<ResourceItem>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ResourceItem>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<ResourceItem> resources = snapshot.data!;
          if (resources.isEmpty) {
            return const Center(child: Text('No donations created yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              itemCount: resources.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final ResourceItem resource = resources[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: resource.primaryPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              AppConfig.resolveUrl(resource.primaryPhotoUrl!),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                return const CircleAvatar(
                                  child: Icon(Icons.broken_image_outlined),
                                );
                              },
                            ),
                          )
                        : const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                    title: Text(resource.title),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_buildSubtitle(resource)),
                    ),
                    trailing: Text(
                      resource.resourceType == 'FOOD'
                          ? formatDateTime(resource.expiresAt)
                          : formatDate(resource.medicineExpiryDate),
                      textAlign: TextAlign.right,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DonationDetailsScreen(resource: resource),
                        ),
                      );
                      setState(() => _future = _load());
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _buildSubtitle(ResourceItem resource) {
    final StringBuffer buffer = StringBuffer(
      '${resource.resourceType} • ${formatStatus(resource.status)} • ${resource.availableQuantity}/${resource.quantity} ${resource.unit}',
    );

    if (resource.resourceType == 'MEDICINE') {
      buffer.write('\nMedical review: ${formatStatus(resource.medicalVerificationStatus)}');
      if (resource.medicalVerificationStatus != 'APPROVED') {
        buffer.write('\nHidden from receivers until medical approval is completed.');
      }
    } else if (resource.claimable) {
      buffer.write('\nVisible to receivers.');
    } else {
      buffer.write('\nCurrently hidden from receivers.');
    }

    return buffer.toString();
  }
}
