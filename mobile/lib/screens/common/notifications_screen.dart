import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/notification_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return NotificationApi(auth.apiClient).mine(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Notifications',
      onLogout: () => auth.logout(),
      child: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<AppNotification>> snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: <Widget>[
                EmptyStateCard(
                  title: 'Unable to load notifications',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.notifications_off_outlined,
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
          final List<AppNotification> notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const EmptyStateCard(
              title: 'No notifications yet',
              message: 'Claim, medicine, delivery, and moderation updates will appear here.',
              icon: Icons.notifications_none_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              itemCount: notifications.length + 1,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  final int unreadCount = notifications.where((AppNotification item) => !item.read).length;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: SectionTitle(
                              title: 'Notification Center',
                              subtitle: unreadCount == 0
                                  ? 'Everything is caught up.'
                                  : '$unreadCount unread update(s)',
                            ),
                          ),
                          if (unreadCount > 0)
                            OutlinedButton(
                              onPressed: _markAllRead,
                              child: const Text('Mark all read'),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                final AppNotification notification = notifications[index - 1];
                return Card(
                  color: notification.read ? null : const Color(0xFFF4F9E9),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            StatusChip(
                              label: notification.read ? 'Read' : 'Unread',
                              status: notification.read ? 'APPROVED' : 'PENDING',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            StatusChip(label: formatNotificationType(notification.type), status: notification.type),
                            StatusChip(label: formatDateTime(notification.createdAt)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(notification.message),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: notification.read
                              ? const Icon(Icons.done_all_rounded)
                              : OutlinedButton(
                                  onPressed: () => _markRead(notification.id),
                                  child: const Text('Mark read'),
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

  Future<void> _markRead(String notificationId) async {
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await NotificationApi(auth.apiClient).markRead(auth.token!, notificationId);
      if (!mounted) return;
      auth.setUnreadNotificationCount((auth.unreadNotificationCount - 1).clamp(0, 9999).toInt());
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }

  Future<void> _markAllRead() async {
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await NotificationApi(auth.apiClient).markAllRead(auth.token!);
      if (!mounted) return;
      auth.setUnreadNotificationCount(0);
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
