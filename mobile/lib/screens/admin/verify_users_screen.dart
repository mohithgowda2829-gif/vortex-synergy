import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/admin_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/pending_verification.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/status_chip.dart';

class VerifyUsersScreen extends StatefulWidget {
  const VerifyUsersScreen({super.key});

  @override
  State<VerifyUsersScreen> createState() => _VerifyUsersScreenState();
}

class _VerifyUsersScreenState extends State<VerifyUsersScreen> {
  late Future<List<PendingVerification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PendingVerification>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return AdminApi(auth.apiClient).pendingVerifications(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Verify Users',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<PendingVerification>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<PendingVerification>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load verification queue',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.verified_outlined,
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

          final List<PendingVerification> items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyStateCard(
              title: 'No pending verifications',
              message: 'New doctor/pharmacist approvals and medicine donor requests will appear here.',
              icon: Icons.task_alt_outlined,
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final PendingVerification item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.subjectName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          StatusChip(label: formatStatus(item.verificationType), status: item.verificationType),
                          StatusChip(label: formatStatus(item.targetType), status: item.targetType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Requested: ${formatDateTime(item.createdAt)}'),
                      if (item.note != null && item.note!.isNotEmpty) Text('Note: ${item.note}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () => _decide(item, true),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () => _decide(item, false),
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
    );
  }

  Future<void> _decide(PendingVerification item, bool approved) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final TextEditingController noteController = TextEditingController(
      text: approved ? 'Approved by admin' : 'Rejected by admin',
    );

    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(approved ? 'Approve verification' : 'Reject verification'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Admin note'),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(noteController.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (note == null) return;

    try {
      await AdminApi(auth.apiClient).decideVerification(
        auth.token!,
        verificationId: item.id,
        approved: approved,
        note: note,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, approved ? 'Verification approved' : 'Verification rejected');
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      noteController.dispose();
    }
  }
}
