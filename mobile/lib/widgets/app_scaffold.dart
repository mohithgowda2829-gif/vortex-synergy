import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/common/notifications_screen.dart';
import 'animated_entry.dart';
import 'animated_gradient_background.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onLogout,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final Future<void> Function()? onLogout;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            if (auth.isAuthenticated)
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                  );
                  if (context.mounted) {
                    await context.read<AuthProvider>().refreshNotificationSummary();
                  }
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    const Icon(Icons.notifications_outlined),
                    if (auth.unreadNotificationCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            auth.unreadNotificationCount > 99
                                ? '99+'
                                : auth.unreadNotificationCount.toString(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ...actions,
            if (onLogout != null)
              IconButton(
                onPressed: () async {
                  await onLogout!.call();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).popUntil((Route<dynamic> route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: AnimatedEntry(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
