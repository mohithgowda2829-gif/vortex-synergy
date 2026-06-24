import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/inventory_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/inventory_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/status_chip.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<InventoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<InventoryItem>> _load() async {
    final AuthProvider auth = context.read<AuthProvider>();
    return InventoryApi(auth.apiClient).mine(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Inventory',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<InventoryItem>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<InventoryItem>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load inventory',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<InventoryItem> items = snapshot.data!;
          if (items.isEmpty) {
            return ListView(
              children: const <Widget>[
                EmptyStateCard(
                  title: 'Inventory is empty',
                  message: 'Completed claims will appear here as usable stock for your organization.',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              children: items.map(_buildCard).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(InventoryItem item) {
    final TextEditingController consumeController = TextEditingController(text: '1');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(item.resourceTitle, style: Theme.of(context).textTheme.titleMedium)),
                  StatusChip(label: formatStatus(item.status), status: item.status),
                ],
              ),
              const SizedBox(height: 12),
              DetailRow(label: 'Donor', value: item.donorName),
              DetailRow(label: 'Received', value: '${item.quantityReceived} ${item.unit}'),
              DetailRow(label: 'Available', value: '${item.quantityAvailable} ${item.unit}'),
              DetailRow(label: 'Consumed', value: '${item.quantityConsumed} ${item.unit}'),
              if (item.branchName != null) DetailRow(label: 'Branch', value: item.branchName!),
              if (item.storageLocation != null) DetailRow(label: 'Storage', value: item.storageLocation!),
              if (item.foodExpiresAt != null) DetailRow(label: 'Food expiry', value: formatDateTime(item.foodExpiresAt)),
              if (item.medicineExpiryDate != null) DetailRow(label: 'Medicine expiry', value: item.medicineExpiryDate.toString()),
              DetailRow(label: 'Source area', value: '${item.area}, ${item.city}'),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: consumeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Consume qty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: item.quantityAvailable <= 0
                        ? null
                        : () => _consume(item, int.tryParse(consumeController.text.trim()) ?? 0),
                    child: const Text('Consume'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _consume(InventoryItem item, int quantity) async {
    if (quantity <= 0) {
      AppFeedback.showError(context, 'Quantity must be at least 1');
      return;
    }
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await InventoryApi(auth.apiClient).consume(
        auth.token!,
        inventoryItemId: item.id,
        quantity: quantity,
        branchName: item.branchName,
        storageLocation: item.storageLocation,
        notes: item.notes,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Inventory updated');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
