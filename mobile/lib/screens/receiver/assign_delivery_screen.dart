import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/delivery_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_validators.dart';
import '../../models/claim_item.dart';
import '../../models/delivery_task.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/section_title.dart';

class AssignDeliveryScreen extends StatefulWidget {
  const AssignDeliveryScreen({super.key, required this.claim});

  final ClaimItem claim;

  @override
  State<AssignDeliveryScreen> createState() => _AssignDeliveryScreenState();
}

class _AssignDeliveryScreenState extends State<AssignDeliveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _orderNumberController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _agentNameController;
  late final TextEditingController _agentMobileController;
  late final TextEditingController _notesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _orderNumberController = TextEditingController();
    _vehicleNumberController = TextEditingController();
    _agentNameController = TextEditingController();
    _agentMobileController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _vehicleNumberController.dispose();
    _agentNameController.dispose();
    _agentMobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Assign Delivery Agent',
      onLogout: () => auth.logout(),
      child: ListView(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle(
                    title: 'Receiver-managed assignment',
                    subtitle: 'These details are visible to the donor and become part of the delivery audit trail.',
                  ),
                  const SizedBox(height: 12),
                  DetailRow(label: 'Resource', value: widget.claim.resourceTitle),
                  DetailRow(label: 'Quantity', value: widget.claim.quantity.toString()),
                  DetailRow(
                    label: 'Reservation',
                    value: widget.claim.pickupConfirmedByReceiver
                        ? 'Confirmed'
                        : 'Confirm the reservation before assigning delivery',
                  ),
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
                      controller: _orderNumberController,
                      validator: (String? value) => AppValidators.required(value, label: 'Order number'),
                      decoration: const InputDecoration(labelText: 'Order number'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vehicleNumberController,
                      validator: (String? value) => AppValidators.required(value, label: 'Vehicle number'),
                      decoration: const InputDecoration(labelText: 'Vehicle number'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _agentNameController,
                      validator: (String? value) => AppValidators.required(value, label: 'Agent name'),
                      decoration: const InputDecoration(labelText: 'Agent name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _agentMobileController,
                      keyboardType: TextInputType.phone,
                      validator: (String? value) => AppValidators.phone(value, label: 'Agent mobile number'),
                      decoration: const InputDecoration(labelText: 'Agent mobile number'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_submitting ? 'Assigning...' : 'Assign Delivery Agent'),
                      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final DeliveryTask delivery = await DeliveryApi(auth.apiClient).assign(
        auth.token!,
        claimId: widget.claim.id,
        orderNumber: _orderNumberController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        agentName: _agentNameController.text.trim(),
        agentMobile: _agentMobileController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Delivery assignment sent to the donor');
      Navigator.of(context).pop(delivery);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
