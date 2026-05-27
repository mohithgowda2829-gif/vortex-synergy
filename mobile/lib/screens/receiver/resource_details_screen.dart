import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/claim_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../config/app_validators.dart';
import '../../models/claim_item.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/photo_gallery.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';
import '../common/timeline_screen.dart';
import 'confirm_pickup_screen.dart';

class ResourceDetailsScreen extends StatefulWidget {
  const ResourceDetailsScreen({super.key, required this.resource});

  final ResourceItem resource;

  @override
  State<ResourceDetailsScreen> createState() => _ResourceDetailsScreenState();
}

class _ResourceDetailsScreenState extends State<ResourceDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  String _pickupMode = 'SELF_PICKUP';
  bool _urgentNeed = false;
  bool _vulnerableReceiver = false;
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ResourceItem resource = widget.resource;
    final bool forceManagedDelivery = resource.requiresReceiverDelivery;

    return AppScaffold(
      title: 'Resource Details',
      onLogout: () => auth.logout(),
      child: ListView(
        children: <Widget>[
          PhotoGallery(photoUrls: resource.photoUrls),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(resource.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  DetailRow(label: 'Donor', value: resource.donorName),
                  DetailRow(label: 'Type', value: resource.resourceType),
                  DetailRow(label: 'Available', value: '${resource.availableQuantity} ${resource.unit}'),
                  DetailRow(label: 'Location', value: '${resource.city}, ${resource.area}'),
                  DetailRow(
                    label: 'Expiry',
                    value: resource.resourceType == 'FOOD'
                        ? formatDateTime(resource.expiresAt)
                        : formatDate(resource.medicineExpiryDate),
                  ),
                  DetailRow(
                    label: 'Pickup support',
                    value: forceManagedDelivery
                        ? 'Receiver-managed delivery is required for this listing'
                        : 'Self pickup is allowed, or you can assign your own delivery agent',
                  ),
                  DetailRow(
                    label: 'Fair access policy',
                    value:
                        'No daily claim cap. Duplicate active reservations on the same listing are blocked, and frequent recent claims reduce priority.',
                  ),
                  if (resource.distanceKm != null)
                    DetailRow(label: 'Distance', value: '${resource.distanceKm} km'),
                  if (resource.description != null && resource.description!.isNotEmpty)
                    DetailRow(label: 'Notes', value: resource.description!),
                  if (resource.resourceType == 'MEDICINE') ...<Widget>[
                    const Divider(height: 28),
                    const SectionTitle(
                      title: 'Medicine compliance',
                      subtitle: 'Only approved, sealed, non-expired medicine is claimable.',
                    ),
                    const SizedBox(height: 12),
                    DetailRow(label: 'Category', value: resource.medicineCategory ?? 'Not tagged'),
                    DetailRow(label: 'Access', value: resource.medicineAccessType ?? 'Not tagged'),
                    DetailRow(
                      label: 'Prescription',
                      value: (resource.prescriptionRequired ?? false) ? 'Required' : 'Not required',
                    ),
                    if (resource.verificationNotes != null && resource.verificationNotes!.isNotEmpty)
                      DetailRow(label: 'Verification notes', value: resource.verificationNotes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      validator: (String? value) {
                        final String? basicValidation = AppValidators.wholeNumber(
                          value,
                          label: 'Claim quantity',
                        );
                        if (basicValidation != null) {
                          return basicValidation;
                        }
                        final int parsed = int.parse(value!.trim());
                        if (parsed > resource.availableQuantity) {
                          return 'Claim quantity cannot exceed available quantity';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'Claim quantity'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pickup Method',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      multiSelectionEnabled: false,
                      emptySelectionAllowed: false,
                      showSelectedIcon: false,
                      selected: <String>{forceManagedDelivery ? 'DELIVERY_ASSIGNMENT' : _pickupMode},
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'SELF_PICKUP',
                          label: Text('Self pickup'),
                          icon: Icon(Icons.person_pin_circle_outlined),
                        ),
                        ButtonSegment<String>(
                          value: 'DELIVERY_ASSIGNMENT',
                          label: Text('Receiver delivery'),
                          icon: Icon(Icons.local_shipping_outlined),
                        ),
                      ],
                      onSelectionChanged: forceManagedDelivery
                          ? null
                          : (Set<String> selection) {
                              setState(() => _pickupMode = selection.first);
                            },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        forceManagedDelivery
                            ? 'This listing requires receiver-managed delivery assignment.'
                            : 'Choose self pickup when the receiver collects it directly.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _urgentNeed,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Urgent need'),
                      subtitle: const Text('Use for urgent medical or highly time-sensitive need.'),
                      onChanged: (bool value) => setState(() => _urgentNeed = value),
                    ),
                    SwitchListTile.adaptive(
                      value: _vulnerableReceiver,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vulnerable receiver'),
                      subtitle: const Text('Feeds the explainable priority engine.'),
                      onChanged: (bool value) => setState(() => _vulnerableReceiver = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
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
                            label: const Text('Timeline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _claim,
                            child: Text(_submitting ? 'Reserving...' : 'Request Resource'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claim() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final ClaimItem claim = await ClaimApi(auth.apiClient).request(
        auth.token!,
        resourceId: widget.resource.id,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        deliveryRequested: widget.resource.requiresReceiverDelivery || _pickupMode == 'DELIVERY_ASSIGNMENT',
        urgentNeed: _urgentNeed,
        vulnerableReceiver: _vulnerableReceiver,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ConfirmPickupScreen(claim: claim)),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
