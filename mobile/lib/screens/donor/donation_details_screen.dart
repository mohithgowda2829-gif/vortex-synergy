import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/resource_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/photo_gallery.dart';
import '../common/timeline_screen.dart';
import 'add_resource_screen.dart';
import 'handover_confirmation_screen.dart';

class DonationDetailsScreen extends StatelessWidget {
  const DonationDetailsScreen({super.key, required this.resource});

  final ResourceItem resource;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Donation Details',
      onLogout: () => auth.logout(),
      child: ListView(
        children: <Widget>[
          PhotoGallery(photoUrls: resource.photoUrls),
          const SizedBox(height: 16),
          if (resource.resourceType == 'MEDICINE' && resource.medicalVerificationStatus != 'APPROVED')
            Card(
              color: const Color(0xFFFFF4DB),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'This medicine listing was created successfully, but receivers cannot see it yet. A doctor or pharmacist must approve it first.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          if (resource.resourceType == 'MEDICINE' && resource.medicalVerificationStatus != 'APPROVED')
            const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(resource.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DetailRow(label: 'Type', value: resource.resourceType),
                  DetailRow(label: 'Status', value: formatStatus(resource.status)),
                  DetailRow(label: 'Quantity', value: '${resource.quantity} ${resource.unit}'),
                  DetailRow(label: 'Available', value: '${resource.availableQuantity} ${resource.unit}'),
                  DetailRow(label: 'Location', value: '${resource.city}, ${resource.area}'),
                  if (resource.latitude != null && resource.longitude != null)
                    DetailRow(label: 'Coordinates', value: '${resource.latitude}, ${resource.longitude}'),
                  DetailRow(
                    label: 'Expiry',
                    value: resource.resourceType == 'FOOD'
                        ? formatDateTime(resource.expiresAt)
                        : formatDate(resource.medicineExpiryDate),
                  ),
                  if (resource.description != null && resource.description!.isNotEmpty)
                    DetailRow(label: 'Notes', value: resource.description!),
                  if (resource.resourceType == 'MEDICINE')
                    ...<Widget>[
                      DetailRow(
                        label: 'Medical review',
                        value: formatStatus(resource.medicalVerificationStatus),
                      ),
                      DetailRow(label: 'Category', value: resource.medicineCategory ?? 'Not tagged'),
                      DetailRow(label: 'Access', value: resource.medicineAccessType ?? 'Not tagged'),
                      DetailRow(
                        label: 'Prescription',
                        value: (resource.prescriptionRequired ?? false) ? 'Required' : 'Not required',
                      ),
                      if (resource.verificationNotes != null && resource.verificationNotes!.isNotEmpty)
                        DetailRow(label: 'Verification notes', value: resource.verificationNotes!),
                    ],
                  DetailRow(
                    label: 'Pickup mode',
                    value: resource.requiresReceiverDelivery
                        ? 'Receiver-managed delivery required'
                        : 'Receiver self-pickup allowed',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_canManage(resource)) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final bool? updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => AddResourceScreen(resource: resource),
                        ),
                      );
                      if (updated == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Resource'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelResource(context, auth, resource),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Resource'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TimelineScreen.resource(
                    resourceId: resource.id,
                    title: 'Resource Timeline',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.timeline_outlined),
            label: const Text('View Resource Timeline'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HandoverConfirmationScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Open Pickup Approval Queue'),
          ),
        ],
      ),
    );
  }

  bool _canManage(ResourceItem resource) {
    return resource.status == 'AVAILABLE' && resource.availableQuantity == resource.quantity;
  }

  Future<void> _cancelResource(BuildContext context, AuthProvider auth, ResourceItem resource) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Cancel resource',
      message: 'This removes the listing from active discovery. Continue?',
      confirmLabel: 'Cancel resource',
    );
    if (!context.mounted || !confirmed) {
      return;
    }

    try {
      await ResourceApi(auth.apiClient).cancel(auth.token!, resource.id);
      if (!context.mounted) return;
      AppFeedback.showSuccess(context, 'Resource cancelled successfully');
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
